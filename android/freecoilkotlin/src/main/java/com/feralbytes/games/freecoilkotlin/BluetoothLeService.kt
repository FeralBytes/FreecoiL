/*
 * Copyright (C) 2020 The FreecoiL Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.feralbytes.games.freecoilkotlin

import android.app.Service
import android.bluetooth.*
import android.content.Context
import android.content.Intent
import android.os.Binder
import android.os.IBinder
import java.util.*

/**
 * Service for managing connection and data communication with a GATT server hosted on a
 * given Bluetooth LE device.
 */
class BluetoothLeService : Service() {
    protected var appContext: Context? = null
    private var mBluetoothManager: BluetoothManager? = null
    private var mBluetoothAdapter: BluetoothAdapter? = null
    private var mBluetoothDeviceAddress: String? = null
    private var mBluetoothGatt: BluetoothGatt? = null
    private var mConnectionState = STATE_DISCONNECTED
    private var mActionAvailable = true
    private var mCharacteristicWriteQueue: Queue<BluetoothGattCharacteristic>? = null
    private var mDescriptorWriteQueue: Queue<BluetoothGattDescriptor>? = null
    private var mCharacteristicReadQueue: Queue<BluetoothGattCharacteristic>? = null
    private var FreecoiLInstance: FreecoiLPlugin? = null
    private var BtLeServiceInstance: BluetoothLeService? = null
    private fun refreshDeviceCache(gatt: BluetoothGatt): Boolean {
        try {
            val localMethod = gatt.javaClass.getMethod("refresh", *arrayOfNulls(0))
            if (localMethod != null) {
                return (localMethod.invoke(gatt, *arrayOfNulls(0)) as Boolean)
            }
        } catch (localException: Exception) {
            FreecoiLInstance!!.logger("$TAG: An exception occured while refreshing device.", 0)
        }
        return false
    }

    // Implements callback methods for GATT events that the app cares about.  For example,
    // connection change and services discovered.
    private val mGattCallback: BluetoothGattCallback = object : BluetoothGattCallback() {
        override fun onConnectionStateChange(gatt: BluetoothGatt, status: Int, newState: Int) {
            val intentAction: String
            if (status == 133) {
                intentAction = ACTION_GATT_DISCONNECTED
                mConnectionState = STATE_DISCONNECTED
                FreecoiLInstance!!.logger("$TAG: Got the status 133 bug, closing gatt", 2)
                broadcastUpdate(intentAction)
                if (mBluetoothGatt != null) {
                    refreshDeviceCache(mBluetoothGatt!!)
                }
                close()
                return
            }
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                intentAction = ACTION_GATT_CONNECTED
                mConnectionState = STATE_CONNECTED
                broadcastUpdate(intentAction)
                FreecoiLInstance!!.logger("$TAG: Connected to GATT server.", 0)
                // Attempts to discover services after successful connection.
                FreecoiLInstance!!.logger("$TAG: Attempting to start service discovery.", 0)
                FreecoiLInstance!!.appActivity!!.runOnUiThread { mBluetoothGatt!!.discoverServices() }
            } else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                intentAction = ACTION_GATT_DISCONNECTED
                mConnectionState = STATE_DISCONNECTED
                FreecoiLInstance!!.logger("$TAG: Disconnected from GATT server: $status", 1)
                broadcastUpdate(intentAction)
                close()
            }
        }

        override fun onServicesDiscovered(gatt: BluetoothGatt, status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                broadcastUpdate(ACTION_GATT_SERVICES_DISCOVERED)
            } else {
                FreecoiLInstance!!.logger("$TAG: onServicesDiscovered received: $status", 0)
            }
        }

        override fun onCharacteristicRead(gatt: BluetoothGatt,
                                          characteristic: BluetoothGattCharacteristic,
                                          status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                FreecoiLInstance!!.logger("$TAG: read success!", 0)
                broadcastUpdate(characteristic)
            } else {
                FreecoiLInstance!!.logger("$TAG: read failed", 1)
            }
            if (mCharacteristicWriteQueue!!.size > 0) {
                if (!mBluetoothGatt!!.writeCharacteristic(mCharacteristicWriteQueue!!.peek())) {
                    FreecoiLInstance!!.logger(TAG + ": Failed to write queued characteristic " + mCharacteristicWriteQueue!!.peek().uuid.toString(), 2)
                }
                mCharacteristicWriteQueue!!.remove()
            } else if (mDescriptorWriteQueue!!.size > 0) {
                if (!mBluetoothGatt!!.writeDescriptor(mDescriptorWriteQueue!!.peek())) {
                    FreecoiLInstance!!.logger(TAG + ": Failed to write queued descriptor " + mDescriptorWriteQueue!!.peek().uuid.toString(), 2)
                }
                mDescriptorWriteQueue!!.remove()
            } else if (mCharacteristicReadQueue!!.size > 0) {
                if (!mBluetoothGatt!!.readCharacteristic(mCharacteristicReadQueue!!.peek())) {
                    FreecoiLInstance!!.logger(TAG + ": Failed to read queued characteristic " + mCharacteristicReadQueue!!.peek().uuid.toString(), 2)
                }
                mCharacteristicReadQueue!!.remove()
            } else {
                mActionAvailable = true
            }
        }

        override fun onCharacteristicWrite(gatt: BluetoothGatt,
                                           characteristic: BluetoothGattCharacteristic,
                                           status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                FreecoiLInstance!!.logger("$TAG: write success!", 0)
            } else {
                FreecoiLInstance!!.logger("$TAG: write failed", 1)
            }
            if (mCharacteristicWriteQueue!!.size > 0) {
                if (!mBluetoothGatt!!.writeCharacteristic(mCharacteristicWriteQueue!!.peek())) {
                    FreecoiLInstance!!.logger(TAG + ": Failed to write queued characteristic " + mCharacteristicWriteQueue!!.peek().uuid.toString(), 2)
                }
                mCharacteristicWriteQueue!!.remove()
            } else if (mDescriptorWriteQueue!!.size > 0) {
                if (!mBluetoothGatt!!.writeDescriptor(mDescriptorWriteQueue!!.peek())) {
                    FreecoiLInstance!!.logger(TAG + ": Failed to write queued descriptor " + mDescriptorWriteQueue!!.peek().uuid.toString(), 2)
                }
                mDescriptorWriteQueue!!.remove()
            } else if (mCharacteristicReadQueue!!.size > 0) {
                if (!mBluetoothGatt!!.readCharacteristic(mCharacteristicReadQueue!!.peek())) {
                    FreecoiLInstance!!.logger(TAG + ": Failed to read queued characteristic " + mCharacteristicReadQueue!!.peek().uuid.toString(), 2)
                }
                mCharacteristicReadQueue!!.remove()
            } else {
                mActionAvailable = true
            }
            broadcastUpdate(CHARACTERISTIC_WRITE_FINISHED)
        }

        override fun onCharacteristicChanged(gatt: BluetoothGatt,
                                             characteristic: BluetoothGattCharacteristic) {
            broadcastUpdate(characteristic)
        }

        override fun onDescriptorWrite(gatt: BluetoothGatt,
                                       descriptor: BluetoothGattDescriptor,
                                       status: Int) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                FreecoiLInstance!!.logger("$TAG: descriptor write success!", 0)
            } else {
                FreecoiLInstance!!.logger("$TAG: descriptor write failed", 1)
            }
            if (mCharacteristicWriteQueue!!.size > 0) {
                if (!mBluetoothGatt!!.writeCharacteristic(mCharacteristicWriteQueue!!.peek())) {
                    FreecoiLInstance!!.logger(TAG + ": Failed to write queued characteristic " + mCharacteristicWriteQueue!!.peek().uuid.toString(), 2)
                }
                mCharacteristicWriteQueue!!.remove()
            } else if (mDescriptorWriteQueue!!.size > 0) {
                if (!mBluetoothGatt!!.writeDescriptor(mDescriptorWriteQueue!!.peek())) {
                    FreecoiLInstance!!.logger(TAG + ": Failed to write queued descriptor " + mDescriptorWriteQueue!!.peek().uuid.toString(), 2)
                }
                mDescriptorWriteQueue!!.remove()
            } else if (mCharacteristicReadQueue!!.size > 0) {
                if (!mBluetoothGatt!!.readCharacteristic(mCharacteristicReadQueue!!.peek())) {
                    FreecoiLInstance!!.logger(TAG + ": Failed to read queued characteristic " + mCharacteristicReadQueue!!.peek().uuid.toString(), 2)
                }
                mCharacteristicReadQueue!!.remove()
            } else {
                mActionAvailable = true
            }
            broadcastUpdate(DESCRIPTOR_WRITE_FINISHED)
        }
    }

    private fun broadcastUpdate(action: String) {
        val intent = Intent(action)
        FreecoiLInstance!!.appContext!!.sendBroadcast(intent)
    }

    private fun broadcastUpdate(characteristic: BluetoothGattCharacteristic) {
        if (UUID_RECOIL_TELEMETRY == characteristic.uuid) {
            val intent = Intent(TELEMETRY_DATA_AVAILABLE)
            FreecoiLInstance!!.appContext!!.sendBroadcast(intent)
        } else if (UUID_RECOIL_ID == characteristic.uuid) {
            val firmwareVer = (characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, 0) shl 8) + characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, 1)
            FreecoiLInstance!!.logger("$TAG: Firmware version: $firmwareVer", 0)
            // This gets the blaster type, 1 for rifle and 2 for pistol
            val intent = Intent(ID_DATA_AVAILABLE)
            val data = characteristic.value
            intent.putExtra(EXTRA_DATA, data[10])
            FreecoiLInstance!!.appContext!!.sendBroadcast(intent)
        } else {
            FreecoiLInstance!!.logger(TAG + ": unexpected characteristic data from " + characteristic.uuid.toString(), 2)
        }
    }

    inner class LocalBinder : Binder() {
        val service: BluetoothLeService
            get() = this@BluetoothLeService
    }

    override fun onBind(intent: Intent): IBinder? {
        return mBinder
    }

    override fun onUnbind(intent: Intent): Boolean {
        // After using a given device, you should make sure that BluetoothGatt.close() is called
        // such that resources are cleaned up properly.  In this particular example, close() is
        // invoked when the UI is disconnected from the Service.
        close()
        return super.onUnbind(intent)
    }

    private val mBinder: IBinder = LocalBinder()

    /**
     * Initializes a reference to the local Bluetooth adapter.
     *
     * @return Return true if the initialization is successful.
     */
    fun initialize(FreecoiLInstanceThis: FreecoiLPlugin?): Boolean {
        // For API level 18 and above, get a reference to BluetoothAdapter through
        // BluetoothManager.
        FreecoiLInstance = FreecoiLInstanceThis
        BtLeServiceInstance = this
        if (mBluetoothManager == null) {
            mBluetoothManager = FreecoiLInstance!!.appContext!!.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            if (mBluetoothManager == null) {
                FreecoiLInstance!!.logger("$TAG: Unable to initialize BluetoothManager.", 2)
                return false
            }
        }
        mBluetoothAdapter = mBluetoothManager!!.adapter
        if (mBluetoothAdapter == null) {
            FreecoiLInstance!!.logger("$TAG: Unable to obtain a BluetoothAdapter.", 2)
            return false
        }
        mCharacteristicWriteQueue = LinkedList()
        mCharacteristicReadQueue = LinkedList()
        mDescriptorWriteQueue = LinkedList()
        return true
    }

    /**
     * Connects to the GATT server hosted on the Bluetooth LE device.
     *
     * @param address The device address of the destination device.
     *
     * @return Return true if the connection is initiated successfully. The connection result
     * is reported asynchronously through the
     * `BluetoothGattCallback#onConnectionStateChange(android.bluetooth.BluetoothGatt, int, int)`
     * callback.
     */
    fun connect(address: String?): Boolean {
        if (mBluetoothAdapter == null || address == null) {
            FreecoiLInstance!!.logger("$TAG: BluetoothAdapter not initialized or unspecified address.", 2)
            return false
        }

        // Previously connected device.  Try to reconnect.
        if (mBluetoothDeviceAddress != null && address == mBluetoothDeviceAddress && mBluetoothGatt != null) {
            FreecoiLInstance!!.logger("$TAG: Trying to use an existing mBluetoothGatt for connection.", 0)
            return if (mBluetoothGatt!!.connect()) {
                mConnectionState = STATE_CONNECTING
                true
            } else {
                false
            }
        }
        val device = mBluetoothAdapter!!.getRemoteDevice(address)
        if (device == null) {
            FreecoiLInstance!!.logger("$TAG: Device not found.  Unable to connect.", 2)
            return false
        }
        // We want to directly connect to the device, so we are setting the autoConnect
        // parameter to false.
        FreecoiLInstance!!.appActivity!!.runOnUiThread { mBluetoothGatt = device.connectGatt(BtLeServiceInstance, false, mGattCallback) }
        FreecoiLInstance!!.logger("$TAG: Trying to create a new connection.", 0)
        mBluetoothDeviceAddress = address
        mConnectionState = STATE_CONNECTING
        return true
    }

    /**
     * Disconnects an existing connection or cancel a pending connection. The disconnection result
     * is reported asynchronously through the
     * `BluetoothGattCallback#onConnectionStateChange(android.bluetooth.BluetoothGatt, int, int)`
     * callback.
     */
    fun disconnect() {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance!!.logger("$TAG: BluetoothAdapter not initialized", 2)
            return
        }
        mBluetoothGatt!!.disconnect()
    }

    /**
     * After using a given BLE device, the app must call this method to ensure resources are
     * released properly.
     */
    fun close() {
        if (mBluetoothGatt == null) {
            return
        }
        mBluetoothGatt!!.close()
        mBluetoothGatt = null
    }

    /**
     * Request a read on a given `BluetoothGattCharacteristic`. The read result is reported
     * asynchronously through the `BluetoothGattCallback#onCharacteristicRead(android.bluetooth.BluetoothGatt, android.bluetooth.BluetoothGattCharacteristic, int)`
     * callback.
     *
     * @param characteristic The characteristic to read from.
     */
    fun readCharacteristic(characteristic: BluetoothGattCharacteristic) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance!!.logger("$TAG: BluetoothAdapter not initialized", 2)
            return
        }
        if (!mActionAvailable) {
            FreecoiLInstance!!.logger("$TAG: Reading not available yet, queuing...", 0)
            mCharacteristicReadQueue!!.add(characteristic)
            return
        }
        if (mBluetoothGatt!!.readCharacteristic(characteristic)) {
            FreecoiLInstance!!.logger("$TAG: read the characteristic", 0)
            mActionAvailable = false
        } else {
            FreecoiLInstance!!.logger("$TAG: failed to read the characteristic", 1)
        }
    }

    fun writeCharacteristic(characteristic: BluetoothGattCharacteristic) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance!!.logger("$TAG: BluetoothAdapter not initialized", 2)
            return
        }
        if (!mActionAvailable) {
            FreecoiLInstance!!.logger("$TAG: Writing not available yet, queuing...", 0)
            mCharacteristicWriteQueue!!.add(characteristic)
            return
        }
        if (mBluetoothGatt!!.writeCharacteristic(characteristic)) {
            //FreecoiLInstance.logger(TAG + ": wrote characteristic", 0);
            mActionAvailable = false
        } else {
            FreecoiLInstance!!.logger("$TAG: failed to write characteristic", 1)
        }
    }

    fun writeDescriptor(descriptor: BluetoothGattDescriptor) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance!!.logger("$TAG: BluetoothAdapter not initialized", 2)
            return
        }
        if (!mActionAvailable) {
            FreecoiLInstance!!.logger("$TAG: Writing not available yet, queuing...", 1)
            mDescriptorWriteQueue!!.add(descriptor)
            return
        }
        if (mBluetoothGatt!!.writeDescriptor(descriptor)) {
            //FreecoiLInstance.logger(TAG + ": wrote descriptor success", 0);
            mActionAvailable = false
        } else {
            FreecoiLInstance!!.logger("$TAG: wrote descriptor FAIL", 1)
        }
    }

    /**
     * Enables or disables notification on a give characteristic.
     *
     * @param characteristic Characteristic to act on.
     * @param enabled If true, enable notification.  False otherwise.
     */
    fun setCharacteristicNotification(characteristic: BluetoothGattCharacteristic,
                                      enabled: Boolean) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance!!.logger("$TAG: BluetoothAdapter not initialized", 2)
            return
        }
        mBluetoothGatt!!.setCharacteristicNotification(characteristic, enabled)
        if (UUID_RECOIL_TELEMETRY == characteristic.uuid) {
            val descriptor = characteristic.getDescriptor(
                    UUID.fromString(GattAttributes.CLIENT_CHARACTERISTIC_CONFIG))
            if (enabled) {
                FreecoiLInstance!!.logger("$TAG: Telling telemetry to enable notifications", 0)
                descriptor.value = BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE
            } else {
                FreecoiLInstance!!.logger("$TAG: Telling telemetry to disable notifications", 0)
                descriptor.value = BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE
            }
            writeDescriptor(descriptor)
        }
    }

    /**
     * Retrieves a list of supported GATT services on the connected device. This should be
     * invoked only after `BluetoothGatt#discoverServices()` completes successfully.
     *
     * @return A `List` of supported services.
     */
    val supportedGattServices: List<BluetoothGattService>?
        get() = if (mBluetoothGatt == null) null else mBluetoothGatt!!.services

    companion object {
        private val TAG = BluetoothLeService::class.java.simpleName
        private const val STATE_DISCONNECTED = 0
        private const val STATE_CONNECTING = 1
        private const val STATE_CONNECTED = 2
        const val ACTION_GATT_CONNECTED = "com.example.bluetooth.le.ACTION_GATT_CONNECTED"
        const val ACTION_GATT_DISCONNECTED = "com.example.bluetooth.le.ACTION_GATT_DISCONNECTED"
        const val ACTION_GATT_SERVICES_DISCOVERED = "com.example.bluetooth.le.ACTION_GATT_SERVICES_DISCOVERED"
        const val TELEMETRY_DATA_AVAILABLE = "com.example.bluetooth.le.TELEMETRY_DATA_AVAILABLE"
        const val ID_DATA_AVAILABLE = "com.example.bluetooth.le.ID_DATA_AVAILABLE"
        const val CHARACTERISTIC_WRITE_FINISHED = "com.example.bluetooth.le.CHARACTERISTIC_WRITE_FINISHED"
        const val DESCRIPTOR_WRITE_FINISHED = "com.example.bluetooth.le.DESCRIPTOR_WRITE_FINISHED"
        const val EXTRA_DATA = "com.example.bluetooth.le.EXTRA_DATA"
        val UUID_RECOIL_TELEMETRY = UUID.fromString(GattAttributes.RECOIL_TELEMETRY_UUID)
        val UUID_RECOIL_ID = UUID.fromString(GattAttributes.RECOIL_ID_UUID)
    }
}