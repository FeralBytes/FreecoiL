/*
 * Copyright (C) 2013 The Android Open Source Project
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

package com.feralbytes.games.freecoiljava;

import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGatt;
import android.bluetooth.BluetoothGattCallback;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattDescriptor;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.content.Intent;
import android.os.Binder;
import android.os.Build;
import android.os.IBinder;
import android.support.annotation.RequiresApi;
import android.util.Log;

import java.lang.reflect.Method;
import java.util.LinkedList;
import java.util.List;
import java.util.Queue;
import java.util.UUID;

import com.feralbytes.games.freecoiljava.FreecoiLPlugin;

/**
 * Service for managing connection and data communication with a GATT server hosted on a
 * given Bluetooth LE device.
 */
public class BluetoothLeService extends Service {
    private final static String TAG = BluetoothLeService.class.getSimpleName();

    protected Context appContext;

    private BluetoothManager mBluetoothManager;
    private BluetoothAdapter mBluetoothAdapter;
    private String mBluetoothDeviceAddress;
    private BluetoothGatt mBluetoothGatt;
    private int mConnectionState = STATE_DISCONNECTED;
    private static final int STATE_DISCONNECTED = 0;
    private static final int STATE_CONNECTING = 1;
    private static final int STATE_CONNECTED = 2;

    public final static String ACTION_GATT_CONNECTED =
            "com.example.bluetooth.le.ACTION_GATT_CONNECTED";
    public final static String ACTION_GATT_DISCONNECTED =
            "com.example.bluetooth.le.ACTION_GATT_DISCONNECTED";
    public final static String ACTION_GATT_SERVICES_DISCOVERED =
            "com.example.bluetooth.le.ACTION_GATT_SERVICES_DISCOVERED";
    public final static String TELEMETRY_DATA_AVAILABLE =
            "com.example.bluetooth.le.TELEMETRY_DATA_AVAILABLE";
    public final static String ID_DATA_AVAILABLE =
            "com.example.bluetooth.le.ID_DATA_AVAILABLE";
    public final static String CHARACTERISTIC_WRITE_FINISHED =
            "com.example.bluetooth.le.CHARACTERISTIC_WRITE_FINISHED";
    public final static String DESCRIPTOR_WRITE_FINISHED =
            "com.example.bluetooth.le.DESCRIPTOR_WRITE_FINISHED";
    public final static String EXTRA_DATA =
            "com.example.bluetooth.le.EXTRA_DATA";

    public final static UUID UUID_RECOIL_TELEMETRY =
            UUID.fromString(GattAttributes.RECOIL_TELEMETRY_UUID);
    public final static UUID UUID_RECOIL_ID =
            UUID.fromString(GattAttributes.RECOIL_ID_UUID);

    private boolean mActionAvailable = true;
    private Queue<BluetoothGattCharacteristic> mCharacteristicWriteQueue;
    private Queue<BluetoothGattDescriptor> mDescriptorWriteQueue;
    private Queue<BluetoothGattCharacteristic> mCharacteristicReadQueue;
    private FreecoiLPlugin FreecoiLInstance;
    private BluetoothLeService BtLeServiceInstance;

    
    private boolean refreshDeviceCache(BluetoothGatt gatt){
        try {
            BluetoothGatt localBluetoothGatt = gatt;
            Method localMethod = localBluetoothGatt.getClass().getMethod("refresh", new Class[0]);
            if (localMethod != null) {
               boolean bool = ((Boolean) localMethod.invoke(localBluetoothGatt, new Object[0])).booleanValue();
                return bool;
             }
        } 
        catch (Exception localException) {
            FreecoiLInstance.logger(TAG + ": An exception occured while refreshing device.", 0);
        }
        return false;
    }

    // Implements callback methods for GATT events that the app cares about.  For example,
    // connection change and services discovered.
    private final BluetoothGattCallback mGattCallback = new BluetoothGattCallback() {
        
        @Override
        public void onConnectionStateChange(BluetoothGatt gatt, int status, int newState) {
            String intentAction;
            if (status == 133) {
                    intentAction = ACTION_GATT_DISCONNECTED;
                    mConnectionState = STATE_DISCONNECTED;
                    FreecoiLInstance.logger(TAG + ": Got the status 133 bug, closing gatt", 2);
                    broadcastUpdate(intentAction);
                    if (mBluetoothGatt != null) {
                        refreshDeviceCache(mBluetoothGatt);
                    }
                    close();
                    return;
            }
            if (newState == BluetoothProfile.STATE_CONNECTED) {
                intentAction = ACTION_GATT_CONNECTED;
                mConnectionState = STATE_CONNECTED;
                broadcastUpdate(intentAction);
                FreecoiLInstance.logger(TAG + ": Connected to GATT server.", 0);
                // Attempts to discover services after successful connection.
                FreecoiLInstance.logger(TAG + ": Attempting to start service discovery.", 0);
                FreecoiLInstance.appActivity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        mBluetoothGatt.discoverServices();
                    }
                });

            } 
            else if (newState == BluetoothProfile.STATE_DISCONNECTED) {
                intentAction = ACTION_GATT_DISCONNECTED;
                mConnectionState = STATE_DISCONNECTED;
                FreecoiLInstance.logger(TAG + ": Disconnected from GATT server: " + status, 1);
                broadcastUpdate(intentAction);
                close();
            }
        }

        
        @Override
        public void onServicesDiscovered(BluetoothGatt gatt, int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                broadcastUpdate(ACTION_GATT_SERVICES_DISCOVERED);
            } 
            else {
                FreecoiLInstance.logger(TAG + ": onServicesDiscovered received: " + status, 0);
            }
        }

        
        @Override
        public void onCharacteristicRead(BluetoothGatt gatt,
                                         BluetoothGattCharacteristic characteristic,
                                         int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                FreecoiLInstance.logger(TAG + ": read success!", 0);
                broadcastUpdate(characteristic);
            } 
            else {
                FreecoiLInstance.logger(TAG + ": read failed", 1);
            }
            if (mCharacteristicWriteQueue.size() > 0) {
                if (!mBluetoothGatt.writeCharacteristic(mCharacteristicWriteQueue.peek())) {
                    FreecoiLInstance.logger(TAG + ": Failed to write queued characteristic " + mCharacteristicWriteQueue.peek().getUuid().toString(), 2);
                }
                mCharacteristicWriteQueue.remove();
            } 
            else if (mDescriptorWriteQueue.size() > 0) {
                if (!mBluetoothGatt.writeDescriptor(mDescriptorWriteQueue.peek())) {
                    FreecoiLInstance.logger(TAG + ": Failed to write queued descriptor " + mDescriptorWriteQueue.peek().getUuid().toString(), 2);
                }
                mDescriptorWriteQueue.remove();
            } 
            else if (mCharacteristicReadQueue.size() > 0) {
                if (!mBluetoothGatt.readCharacteristic(mCharacteristicReadQueue.peek())) {
                    FreecoiLInstance.logger(TAG + ": Failed to read queued characteristic " + mCharacteristicReadQueue.peek().getUuid().toString(), 2);
                }
                mCharacteristicReadQueue.remove();
            } 
            else {
                mActionAvailable = true;
            }
        }

        
        @Override
        public void onCharacteristicWrite(BluetoothGatt gatt,
                                         BluetoothGattCharacteristic characteristic,
                                         int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                FreecoiLInstance.logger(TAG + ": write success!", 0);
            } 
            else {
                FreecoiLInstance.logger(TAG + ": write failed", 1);
            }
            if (mCharacteristicWriteQueue.size() > 0) {
                if (!mBluetoothGatt.writeCharacteristic(mCharacteristicWriteQueue.peek())) {
                    FreecoiLInstance.logger(TAG + ": Failed to write queued characteristic " + mCharacteristicWriteQueue.peek().getUuid().toString(), 2);
                }
                mCharacteristicWriteQueue.remove();
            } 
            else if (mDescriptorWriteQueue.size() > 0) {
                if (!mBluetoothGatt.writeDescriptor(mDescriptorWriteQueue.peek())) {
                    FreecoiLInstance.logger(TAG + ": Failed to write queued descriptor " + mDescriptorWriteQueue.peek().getUuid().toString(), 2);
                }
                mDescriptorWriteQueue.remove();
            } 
            else if (mCharacteristicReadQueue.size() > 0) {
                if (!mBluetoothGatt.readCharacteristic(mCharacteristicReadQueue.peek())) {
                    FreecoiLInstance.logger(TAG + ": Failed to read queued characteristic " + mCharacteristicReadQueue.peek().getUuid().toString(), 2);
                }
                mCharacteristicReadQueue.remove();
            } 
            else {
                mActionAvailable = true;
            }
            broadcastUpdate(CHARACTERISTIC_WRITE_FINISHED);
        }

        
        @Override
        public void onCharacteristicChanged(BluetoothGatt gatt,
                                            BluetoothGattCharacteristic characteristic) {
            broadcastUpdate(characteristic);
        }

        
        @Override
        public void onDescriptorWrite(BluetoothGatt gatt,
                                          BluetoothGattDescriptor descriptor,
                                          int status) {
            if (status == BluetoothGatt.GATT_SUCCESS) {
                FreecoiLInstance.logger(TAG + ": descriptor write success!", 0);
            } 
            else {
                FreecoiLInstance.logger(TAG + ": descriptor write failed", 1);
            }
            if (mCharacteristicWriteQueue.size() > 0) {
                if (!mBluetoothGatt.writeCharacteristic(mCharacteristicWriteQueue.peek())) {
                    FreecoiLInstance.logger(TAG + ": Failed to write queued characteristic " + mCharacteristicWriteQueue.peek().getUuid().toString(), 2);
                }
                mCharacteristicWriteQueue.remove();
            } 
            else if (mDescriptorWriteQueue.size() > 0) {
                if (!mBluetoothGatt.writeDescriptor(mDescriptorWriteQueue.peek())) {
                    FreecoiLInstance.logger(TAG + ": Failed to write queued descriptor " + mDescriptorWriteQueue.peek().getUuid().toString(), 2);
                }
                mDescriptorWriteQueue.remove();
            } 
            else if (mCharacteristicReadQueue.size() > 0) {
                if (!mBluetoothGatt.readCharacteristic(mCharacteristicReadQueue.peek())) {
                    FreecoiLInstance.logger(TAG + ": Failed to read queued characteristic " + mCharacteristicReadQueue.peek().getUuid().toString(), 2);
                }
                mCharacteristicReadQueue.remove();
            } 
            else {
                mActionAvailable = true;
            }
            broadcastUpdate(DESCRIPTOR_WRITE_FINISHED);
        }
    };

    
    private void broadcastUpdate(final String action) {
        final Intent intent = new Intent(action);
        FreecoiLInstance.appContext.sendBroadcast(intent);
    }

    
    private void broadcastUpdate(final BluetoothGattCharacteristic characteristic) {
        if (UUID_RECOIL_TELEMETRY.equals((characteristic.getUuid()))) {
            final Intent intent = new Intent(TELEMETRY_DATA_AVAILABLE);
            FreecoiLInstance.appContext.sendBroadcast(intent);
        } 
        else if (UUID_RECOIL_ID.equals((characteristic.getUuid()))) {
            int firmwareVer = (characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, 0) << 8) + characteristic.getIntValue(BluetoothGattCharacteristic.FORMAT_UINT8, 1);		
            FreecoiLInstance.logger(TAG + ": Firmware version: " + firmwareVer, 0);
            // This gets the blaster type, 1 for rifle and 2 for pistol
            final Intent intent = new Intent(ID_DATA_AVAILABLE);
            final byte[] data = characteristic.getValue();
            intent.putExtra(EXTRA_DATA, data[10]);
            FreecoiLInstance.appContext.sendBroadcast(intent);
        } 
        else {
            FreecoiLInstance.logger(TAG + ": unexpected characteristic data from " + characteristic.getUuid().toString(), 2);
        }
    }

    public class LocalBinder extends Binder {
        BluetoothLeService getService() {
            return BluetoothLeService.this;
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    @Override
    public boolean onUnbind(Intent intent) {
        // After using a given device, you should make sure that BluetoothGatt.close() is called
        // such that resources are cleaned up properly.  In this particular example, close() is
        // invoked when the UI is disconnected from the Service.
        close();
        return super.onUnbind(intent);
    }

    private final IBinder mBinder = new LocalBinder();

    /**
     * Initializes a reference to the local Bluetooth adapter.
     *
     * @return Return true if the initialization is successful.
     */
    
    public boolean initialize(FreecoiLPlugin FreecoiLInstanceThis) {
        // For API level 18 and above, get a reference to BluetoothAdapter through
        // BluetoothManager.
        FreecoiLInstance = FreecoiLInstanceThis;
        BtLeServiceInstance = this;
        if (mBluetoothManager == null) {
            mBluetoothManager = (BluetoothManager) FreecoiLInstance.appContext.getSystemService(Context.BLUETOOTH_SERVICE);
            if (mBluetoothManager == null) {
                FreecoiLInstance.logger(TAG + ": Unable to initialize BluetoothManager.", 2);
                return false;
            }
        }

        mBluetoothAdapter = mBluetoothManager.getAdapter();
        if (mBluetoothAdapter == null) {
            FreecoiLInstance.logger(TAG + ": Unable to obtain a BluetoothAdapter.", 2);
            return false;
        }

        mCharacteristicWriteQueue = new LinkedList<>();
        mCharacteristicReadQueue = new LinkedList<>();
        mDescriptorWriteQueue = new LinkedList<>();

        return true;
    }

    /**
     * Connects to the GATT server hosted on the Bluetooth LE device.
     *
     * @param address The device address of the destination device.
     *
     * @return Return true if the connection is initiated successfully. The connection result
     *         is reported asynchronously through the
     *         {@code BluetoothGattCallback#onConnectionStateChange(android.bluetooth.BluetoothGatt, int, int)}
     *         callback.
     */
    
    public boolean connect(final String address) {
        if (mBluetoothAdapter == null || address == null) {
            FreecoiLInstance.logger(TAG + ": BluetoothAdapter not initialized or unspecified address.", 2);
            return false;
        }

        // Previously connected device.  Try to reconnect.
        if (mBluetoothDeviceAddress != null && address.equals(mBluetoothDeviceAddress)
                && mBluetoothGatt != null) {
            FreecoiLInstance.logger(TAG + ": Trying to use an existing mBluetoothGatt for connection.", 0);
            if (mBluetoothGatt.connect()) {
                mConnectionState = STATE_CONNECTING;
                return true;
            } 
            else {
                return false;
            }
        }

        final BluetoothDevice device = mBluetoothAdapter.getRemoteDevice(address);
        if (device == null) {
            FreecoiLInstance.logger(TAG + ": Device not found.  Unable to connect.", 2);
            return false;
        }
        // We want to directly connect to the device, so we are setting the autoConnect
        // parameter to false.
        FreecoiLInstance.appActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                mBluetoothGatt = device.connectGatt(BtLeServiceInstance, false, mGattCallback);
            }
        });
        FreecoiLInstance.logger(TAG + ": Trying to create a new connection.", 0);
        mBluetoothDeviceAddress = address;
        mConnectionState = STATE_CONNECTING;
        return true;
    }

    /**
     * Disconnects an existing connection or cancel a pending connection. The disconnection result
     * is reported asynchronously through the
     * {@code BluetoothGattCallback#onConnectionStateChange(android.bluetooth.BluetoothGatt, int, int)}
     * callback.
     */
    
    public void disconnect() {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance.logger(TAG + ": BluetoothAdapter not initialized", 2);
            return;
        }
        mBluetoothGatt.disconnect();
    }

    /**
     * After using a given BLE device, the app must call this method to ensure resources are
     * released properly.
     */
    public void close() {
        if (mBluetoothGatt == null) {
            return;
        }
        mBluetoothGatt.close();
        mBluetoothGatt = null;
    }

    /**
     * Request a read on a given {@code BluetoothGattCharacteristic}. The read result is reported
     * asynchronously through the {@code BluetoothGattCallback#onCharacteristicRead(android.bluetooth.BluetoothGatt, android.bluetooth.BluetoothGattCharacteristic, int)}
     * callback.
     *
     * @param characteristic The characteristic to read from.
     */
    
    public void readCharacteristic(BluetoothGattCharacteristic characteristic) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance.logger(TAG + ": BluetoothAdapter not initialized", 2);
            return;
        }
        if ((!mActionAvailable)) {
            FreecoiLInstance.logger(TAG + ": Reading not available yet, queuing...", 0);
            mCharacteristicReadQueue.add(characteristic);
            return;
        }
        if (mBluetoothGatt.readCharacteristic(characteristic)) {
            FreecoiLInstance.logger(TAG + ": read the characteristic", 0);
            mActionAvailable = false;
        } 
        else {
            FreecoiLInstance.logger(TAG + ": failed to read the characteristic", 1);
        }
    }

    
    public void writeCharacteristic(BluetoothGattCharacteristic characteristic) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance.logger(TAG + ": BluetoothAdapter not initialized", 2);
            return;
        }
        if ((!mActionAvailable)) {
            FreecoiLInstance.logger(TAG + ": Writing not available yet, queuing...", 0);
            mCharacteristicWriteQueue.add(characteristic);
            return;
        }
        if (mBluetoothGatt.writeCharacteristic(characteristic)) {
            //FreecoiLInstance.logger(TAG + ": wrote characteristic", 0);
            mActionAvailable = false;
        } 
        else {
            FreecoiLInstance.logger(TAG + ": failed to write characteristic", 1);
        }
    }

    
    public void writeDescriptor(BluetoothGattDescriptor descriptor) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance.logger(TAG + ": BluetoothAdapter not initialized", 2);
            return;
        }
        if (!mActionAvailable) {
            FreecoiLInstance.logger(TAG + ": Writing not available yet, queuing...", 1);
            mDescriptorWriteQueue.add(descriptor);
            return;
        }
        if (mBluetoothGatt.writeDescriptor(descriptor)) {
            //FreecoiLInstance.logger(TAG + ": wrote descriptor success", 0);
            mActionAvailable = false;
        } 
        else {
            FreecoiLInstance.logger(TAG + ": wrote descriptor FAIL", 1);
        }
    }

    /**
     * Enables or disables notification on a give characteristic.
     *
     * @param characteristic Characteristic to act on.
     * @param enabled If true, enable notification.  False otherwise.
     */
    
    public void setCharacteristicNotification(BluetoothGattCharacteristic characteristic,
                                              boolean enabled) {
        if (mBluetoothAdapter == null || mBluetoothGatt == null) {
            FreecoiLInstance.logger(TAG + ": BluetoothAdapter not initialized", 2);
            return;
        }
        mBluetoothGatt.setCharacteristicNotification(characteristic, enabled);

        if (UUID_RECOIL_TELEMETRY.equals(characteristic.getUuid())) {
            BluetoothGattDescriptor descriptor = characteristic.getDescriptor(
                    UUID.fromString(GattAttributes.CLIENT_CHARACTERISTIC_CONFIG));
            if (enabled) {
                FreecoiLInstance.logger(TAG + ": Telling telemetry to enable notifications", 0);
                descriptor.setValue(BluetoothGattDescriptor.ENABLE_NOTIFICATION_VALUE);
            } 
            else {
                FreecoiLInstance.logger(TAG + ": Telling telemetry to disable notifications", 0);
                descriptor.setValue(BluetoothGattDescriptor.DISABLE_NOTIFICATION_VALUE);
            }
            writeDescriptor(descriptor);
        }
    }

    /**
     * Retrieves a list of supported GATT services on the connected device. This should be
     * invoked only after {@code BluetoothGatt#discoverServices()} completes successfully.
     *
     * @return A {@code List} of supported services.
     */
    public List<BluetoothGattService> getSupportedGattServices() {
        if (mBluetoothGatt == null) return null;

        return mBluetoothGatt.getServices();
    }
}

