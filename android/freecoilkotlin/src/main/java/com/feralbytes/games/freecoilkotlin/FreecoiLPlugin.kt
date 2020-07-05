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

import android.app.Activity
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothGattCharacteristic
import android.bluetooth.BluetoothManager
import android.bluetooth.le.BluetoothLeScanner
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.content.*
import android.content.pm.PackageManager
import android.os.IBinder
import android.os.Vibrator
import android.util.Log
import android.view.View
import android.widget.Toast
import com.feralbytes.games.freecoilkotlin.BluetoothLeService.LocalBinder
import org.godotengine.godot.Godot
import org.godotengine.godot.GodotLib
import org.godotengine.godot.plugin.GodotPlugin
import java.util.*
import javax.microedition.khronos.opengles.GL10
import kotlin.experimental.and

//import androidx.fragment.app.FragmentActivity;
class FreecoiLPlugin(godot: Godot?) : GodotPlugin(godot) {
    @JvmField
    var appActivity: Activity? = null
    @JvmField
    var appContext: Context? = null
    var appInstance: FreecoiLPlugin
    private var instanceId = 0
    private var initialized = false
    private var bluetoothAdapter: BluetoothAdapter? = null
    private var bluetoothService: BluetoothLeService? = null
    private var bluetoothScanner: BluetoothLeScanner? = null
    private var bluetoothManager: BluetoothManager? = null
    private val bluetoothConnected = false
    private var bluetoothScanning = false
    private var vibrator: Vibrator? = null
    private var btDeviceAddress = "" // MAC address of the tagger
    private var toastDisplayLength = 0

    /* Code specific to BluetoothLeGATT. */
    private var BLEServiceConnection: ServiceConnection? = null
    private var telemetryCharacteristic: BluetoothGattCharacteristic? = null
    private var commandCharacteristic: BluetoothGattCharacteristic? = null
    private var configCharacteristic: BluetoothGattCharacteristic? = null

    @Volatile
    private var trackedPlayerId = 0

    @Volatile
    private var trackedCommandId = 0

    @Volatile
    private var trackedShotsRemaining = 0

    private val trackedHitById1 = 0

    private val trackedHitById2 = 0

    @Volatile
    private var trackedTriggerBtnCounter = 0

    @Volatile
    private var trackedReloadBtnCounter = 0

    @Volatile
    private var trackedThumbBtnCounter = 0

    @Volatile
    private var trackedPowerBtnCounter = 0

    @Volatile
    private var trackedBatteryLvl = 0

    private val trackedShotId1 = 0

    private val trackedShotId2 = 0

    /* **********************************************************************
     * Public Methods
     * ********************************************************************** */
    override fun getPluginName(): String {
        return "FreecoiL"
    }

    override fun getPluginMethods(): List<String> {
        return Arrays.asList("hello", "init", "bluetoothStatus",
                "enableBluetooth", "fineAccessPermissionStatus", "enableFineAccess", "startBluetoothScan",
                "stopBluetoothScan", "vibrate", "setLaserId", "startReload", "finishReload", "setShotMode",
                "enableRecoil")
    }

    fun hello(): String {
        Log.i(TAG, "Got the appActivity.")
        return HELLO_WORLD
    }

    fun init(pInstanceId: Int) {
        if (!initialized) {
            instanceId = pInstanceId
            bluetoothService = BluetoothLeService()
            if (!bluetoothService!!.initialize(appInstance)) {
                logger("Unable to initialize Bluetooth Low Energy Service!", 4)
            }
            vibrator = appContext!!.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
            GodotLib.calldeferred(instanceId.toLong(), "_on_mod_init", arrayOf())
            logger("FreecoiL Kotlin module initialized.", 1)
            initialized = true
        }
    }

    fun bluetoothStatus(): Int {
        /* Must Initialize a Bluetooth adapter for API 18+.*/
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter()
        // Checks if Bluetooth is supported on the device.
        if (bluetoothAdapter == null) {
            logger("Error: Bluetooth not supported!", 4)
            //finish();
            return 2 // Error Code for Bluetooth Not Supported.
        }
        return if (bluetoothAdapter!!.isEnabled) {
            bluetoothManager = appContext!!.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
            bluetoothScanner = bluetoothAdapter!!.bluetoothLeScanner
            1
        } else {
            0
        }
    }

    fun enableBluetooth() {
        val intentBtEnabled = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        /* The REQUEST_ENABLE_BT constant passed to startActivityForResult() is a locally defined integer
               (which must be greater than 0), that the system passes back to you in your onActivityResult()
               implementation as the requestCode parameter. */
        val REQUEST_ENABLE_BT = 1
        appActivity!!.startActivityForResult(intentBtEnabled, REQUEST_ENABLE_BT)
        return
    }

    fun startBluetoothScan() {
        if (bluetoothManager == null) {
            logger("Failed to get Bluetooth service", 4)
            return
        }
        logger("Starting Bluetooth scan", 1)
        bluetoothScanner!!.startScan(anyLeScanCallbacks)
        bluetoothScanning = true
    }

    fun stopBluetoothScan() {
        bluetoothScanner!!.stopScan(anyLeScanCallbacks)
    }

    private fun vibrate(durationMillis: Int) {
        vibrator!!.vibrate(durationMillis.toLong())
    }

    fun setLaserId(player_id: Int) {
        trackedPlayerId = player_id
        val command = ByteArray(20)
        commandId = (commandId + COMMAND_ID_INCREMENT).toByte()
        command[0] = commandId
        command[2] = 0x80.toByte()
        command[4] = trackedPlayerId.toByte()
        commandCharacteristic!!.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        commandCharacteristic!!.value = command
        bluetoothService!!.writeCharacteristic(commandCharacteristic!!)
    }

    /* Initial reload command that tells the tagger not to shoot anymore (or maybe it just sets the
       remaining shot counter to 0). It also sets the tagger in what I guess is status 0x03 instead
       of the usual 0x02. The command format is F0 00 02 00 PLAYER_ID and then 0 filled to the end. */
    fun startReload() {
        if (commandCharacteristic == null || bluetoothService == null) return
        logger("Started reloading.", 1)
        val command = ByteArray(20)
        commandId = (commandId + COMMAND_ID_INCREMENT).toByte()
        command[0] = commandId
        command[2] = 0x02.toByte() // Start reload.
        command[4] = trackedPlayerId.toByte()
        /*command[5] = WEAPON_PROFILE; // changing profiles during the first stage of reload doesn't
          really do anything since the blaster can't shoot in this state anyway*/commandCharacteristic!!.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        commandCharacteristic!!.value = command
        bluetoothService!!.writeCharacteristic(commandCharacteristic!!)
    }

    /* Second stage of the reload commands which tells the tagger how many shots to load and allows
       it to shoot again. Command format is 00 00 04 00 PLAYER_ID 00 SHOT_COUNT and then 0 filled. */
    fun finishReload(magazine: Int) {
        if (commandCharacteristic == null || bluetoothService == null) return
        logger("Finishing reloading.", 1)
        val command = ByteArray(20)
        commandId = (commandId + COMMAND_ID_INCREMENT).toByte()
        command[0] = commandId
        command[2] = 0x04.toByte() // Finish reload.
        command[4] = trackedPlayerId.toByte()
        command[5] = WEAPON_PROFILE
        command[6] = magazine.toByte() // Is the size of a reload.
        commandCharacteristic!!.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        commandCharacteristic!!.value = command
        bluetoothService!!.writeCharacteristic(commandCharacteristic!!)
    }

    /* Config 00 00 09 xx yy ff c8 ff ff 80 01 34 - xx is the number of shots and if you set yy to 01 for
       full auto for xx shots or 00 for single shot mode, increasing yy decreases Rate of Fire.
       Setting 03 03 for shots and Rate of Fire will give a good 3 shot burst, 03 01 is so fast that you
       only feel 1 recoil for 3 shots */
    fun setShotMode(shotMode: Int, firingMode: Int) {
        if (configCharacteristic == null || bluetoothService == null) return
        val config = ByteArray(20)
        config[0] = WEAPON_PROFILE
        config[2] = 0x09.toByte()
        config[7] = 0xFF.toByte()
        config[8] = 0xFF.toByte()
        config[9] = 0x80.toByte() // Recoil strength
        config[10] = 0x02.toByte()
        config[11] = 0x34.toByte()
        if (shotMode == SHOT_MODE_SINGLE) {
            config[3] = 0xFE.toByte()
            config[4] = 0x00.toByte()
        } else if (shotMode == SHOT_MODE_BURST) {
            config[3] = 0x03.toByte()
            config[4] = 0x03.toByte()
            if (laserType == BLASTER_TYPE_RIFLE) config[9] = 0x78.toByte() // Reduce rifle recoil strength to allow 3 recoils to occur in time.
        } else if (shotMode == SHOT_MODE_FULL_AUTO) {
            config[3] = 0xFE.toByte()
            config[4] = 0x01.toByte()
        }
        when (firingMode) {
            FIRING_MODE_OUTDOOR_NO_CONE -> {
                config[5] = 0xFF.toByte()
                config[6] = 0x00.toByte()
            }
            FIRING_MODE_OUTDOOR_WITH_CONE -> {
                config[5] = 0xFF.toByte()
                config[6] = 0xC8.toByte()
            }
            FIRING_MODE_INDOOR_NO_CONE -> {
                config[5] = 0x19.toByte()
                config[6] = 0x00.toByte()
            }
        }
        configCharacteristic!!.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        configCharacteristic!!.value = config
        bluetoothService!!.writeCharacteristic(configCharacteristic!!)
    }

    /* Config 10 00 02 02 ff and 15 sets of 00 disables recoil
       Config 10 00 02 03 ff and 15 sets of 00 enables recoil */
    fun enableRecoil(enabled: Boolean) {
        if (configCharacteristic == null || bluetoothService == null) return
        val config = ByteArray(20)
        config[0] = 0x10.toByte()
        config[2] = 0x02.toByte()
        config[4] = 0xFF.toByte()
        if (enabled) {
            config[3] = 0x03.toByte()
        } else {
            config[3] = 0x02.toByte()
        }
        configCharacteristic!!.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        configCharacteristic!!.value = config
        bluetoothService!!.writeCharacteristic(configCharacteristic!!)
    }

    /* **********************************************************************
     * Private Methods
     * ********************************************************************** */
    private fun makeToast(message: String, displayLong: Boolean) {
        toastDisplayLength = if (displayLong) {
            Toast.LENGTH_LONG
        } else {
            Toast.LENGTH_SHORT
        }
        appActivity!!.runOnUiThread { Toast.makeText(appActivity, message, toastDisplayLength).show() }
    }

    fun logger(message: String, level: Int) {
        /* Debug Levels:
           0 = debug
           1 = info
           2 = warning
           3 = error
           4 = critical
           5 = exception */
        GodotLib.calldeferred(instanceId.toLong(), "_new_status", arrayOf(message, level))
        if (level >= 2) {
            makeToast(message, true)
        }
    }

    private fun setupBLEServiceConnection() {
        BLEServiceConnection = object : ServiceConnection {
            override fun onServiceConnected(componentName: ComponentName, service: IBinder) {
                bluetoothService = (service as LocalBinder).service
                if (!bluetoothService!!.initialize(appInstance)) {
                    logger("Unable to initialize Bluetooth LE Service!", 5)
                    //finish();
                }
                // Automatically connects to the device upon successful start-up initialization.
                appActivity!!.runOnUiThread { bluetoothService!!.connect(btDeviceAddress) }
                // TODO: Send Godot the new perfered laser Tagger for reconnects.
            }

            override fun onServiceDisconnected(componentName: ComponentName) {
                bluetoothService = null
            }
        }
        bluetoothService!!.initialize(appInstance)
        appActivity!!.runOnUiThread { bluetoothService!!.connect(btDeviceAddress) }
        val gattServiceIntent = Intent(appActivity!!.baseContext, BluetoothLeService::class.java)
        appContext!!.registerReceiver(mGattUpdateReceiver, makeGattUpdateIntentFilter())
    }

    /* Telemetry data is 20 bytes of raw data in the following format:
       00 seems to be part of a continuous counter, first byte always 0 and second byte counts 0 to F, increments with each packet sent
       01 player ID, 01, 02, 03, etc. 00 when not set
       02 first byte is the power button 0 unpressed and 1 for pressed, second is button presses, 01 for trigger, 02 for reload, 04 for back button, add them together for pressing multiple buttons, so 07 means all three buttons are being pressed
       03 counters for the number of times a button has been pressed, the first byte is reload presses, second byte is trigger presses
       04 again a button counter, first byte is unused, second byte is for back/thumb/voice button presses
       05 first byte unused, second byte is a count of power button presses
       06 seem to be part of a continuous counter or otherwise just random???
       07 battery level - 10 is brand new alkalines, 0E for fully charged rechargeables with 0D showing up pretty quick, drops significantly when shooting
       08 00 related to being hit by ID 1, usually around 3* so 3D or 3E but somewhat random
       09 hit by player ID 1, player 1 seems to be 0x04 and player 2 is 0x08, 0x0C, 0x10, 0x14, 0x18
       10 related to being hit by ID 1 but fairly random in the 6* and 7* range
       11 related to being hit by ID 2, usually around 3* so 3D or 3E but somewhat random
       12 hit by player ID 2, player 1 seems to be 0x04 and player 2 is 0x08, sometimes this is the same as ID 1 but sometimes different if being shot by 2 people at once
       13 related to being hit by ID 2 but fairly random in the 6* and 7* range
       14 how many shots you have left, starts out at 0x1e which would be 30 in decimal and decreases when you pull the trigger
       15 usually 02 but I have seen 03 during reload wait... some kind of status?
       16 starts as 02 but changes to 00 after player ID is set
       17 00 Unused?
       18 00 Unused?
       19 00 Unused?
     */
    private fun processTelemetryData() {
        /* https://wiki.laserswarm.com/wiki/Recoil:Main_Page */
        val data = telemetryCharacteristic!!.value
        if (data != null && data.size > 0) {
            val continuousCounter: Int = (data[RECOIL_OFFSET_COMMAND_ID] and 0x0F.toByte()).toInt()
            val commandId: Int = (data[RECOIL_OFFSET_COMMAND_ID].toInt() shr 4 and 0x0F).toInt()
            if (commandId != trackedCommandId) {
                trackedCommandId = commandId
                GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_commandId", arrayOf<Any>(trackedCommandId))
            }
            val playerId = data[RECOIL_OFFSET_PLAYER_ID].toInt()
            if (playerId != trackedPlayerId) {
                trackedPlayerId = playerId
                GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_playerId", arrayOf<Any>(trackedPlayerId))
            }
            val buttonsPressed = data[RECOIL_OFFSET_BUTTONS_BITMASK].toInt()
            if (buttonsPressed != 0) {
                GodotLib.calldeferred(instanceId.toLong(), "_changed_telem_button_pressed", arrayOf<Any>(buttonsPressed))
            }
            /* Rather than monitor if a button is currently pressed, we monitor the counter. Usually
               when the player presses a button, we see many packets showing that the button is
               pressed. We don't want to toggle recoil or modes with every packet we receive so it
               makes more sense to just monitor when the counter changes so we can toggle exactly
               once each time that button is pressed. */
            val triggerBtnCounter: Int = (data[RECOIL_OFFSET_RELOAD_TRIGGER_COUNTER] and 0x0F.toByte()).toInt()
            if (triggerBtnCounter != trackedTriggerBtnCounter) {
                trackedTriggerBtnCounter = triggerBtnCounter
                GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_triggerBtnCounter", arrayOf<Any>(trackedTriggerBtnCounter))
            }
            /* NOTE: Below is a conversion performed on the nibble (last/low 4-bits) to make it act
            * as a proper 4-bit int which counts 0-15. */
            val reloadBtnCounter: Int = (data[RECOIL_OFFSET_RELOAD_TRIGGER_COUNTER].toInt() shr 4 and 0x0F).toInt()
            if (reloadBtnCounter != trackedReloadBtnCounter) {
                trackedReloadBtnCounter = reloadBtnCounter
                GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_reloadBtnCounter", arrayOf<Any>(trackedReloadBtnCounter))
            }
            val thumbBtnCounter = data[RECOIL_OFFSET_THUMB_COUNTER].toInt()
            if (thumbBtnCounter != trackedThumbBtnCounter) {
                trackedThumbBtnCounter = thumbBtnCounter
                GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_thumbBtnCounter", arrayOf<Any>(trackedThumbBtnCounter))
            }
            val powerBtnCounter = data[RECOIL_OFFSET_POWER_COUNTER].toInt()
            if (powerBtnCounter != trackedPowerBtnCounter) {
                trackedPowerBtnCounter = powerBtnCounter
                GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_powerBtnCounter", arrayOf<Any>(trackedPowerBtnCounter))
            }
            /* We send the battery telemetry every time, so we can track the battery average
               and we use it to track if we are still connected to the gun. */
            val batteryLvl = data[RECOIL_OFFSET_BATTERY_LEVEL].toInt()
            trackedBatteryLvl = batteryLvl
            GodotLib.calldeferred(instanceId.toLong(), "_laser_telem_batteryLvl", arrayOf<Any>(trackedBatteryLvl))
            /* bytes are always signed in Java and if you don't do "& 0xFF" here, you will get
               negative numbers in the hitById# field when using player IDs > 32 */
            /* shotById1 defaults to 0 and a shot counter of 0. So using a player ID of 0 would
               result in missing every 8th shot even with complex logic.
               shotById1 is only the left most or most significant 6 bytes. So a max of 0-63.
               So 62 players max, because we do not use 0 since it is default for no shot.*/
            val shotById1: Int = data[RECOIL_OFFSET_HIT_BY1].toInt() and 0xFF shr 2
            val shotById2: Int = data[RECOIL_OFFSET_HIT_BY2].toInt() and 0xFF shr 2
            /* The first 2 most significant bits of RECOIL_OFFSET_HIT_BY1 are the
                least 2 significant bits of the weapon profile ID*/
            val wpnProfileLeast: Int = data[RECOIL_OFFSET_HIT_BY1].toInt() and 0b11
            /* The 2 least significant bits of RECOIL_OFFSET_HIT_BY2 are the 2 most
               significant bits of the weapon profile ID being used (combine with
               2 most significant bits from byte 8 which is RECOIL_OFFSET_HIT_BY1_SHOTID )*/
            val wpnProfileMost: Int = data[RECOIL_OFFSET_HIT_BY2].toInt() and 0b11
            /* Commented out until we are ready to implement it.
            logger("*** wpnProfileLeast = " + wpnProfileLeast + "  | wpnProfileMost = "
                + wpnProfileMost, 1);
            */
            /* Trying to extract the charge level. It is the middle 3 bits.*/
            val chargeLevel: Int = data[RECOIL_OFFSET_HIT_BY1_SHOTID].toInt() shr 2
            val chargeLevel2 = chargeLevel and 0b111
            /* Commented out until we are ready to implement it.
            logger("chargeLevel = " + chargeLevel + "  | chargeLevel2 = " +
                chargeLevel2 + "  | chargeLevel3 = " + chargeLevel3, 1);
            */
            // Only the right-most or least significant 3 bits make up the shot Counter, octal.
            val shotCounter1: Int = (data[RECOIL_OFFSET_HIT_BY1_SHOTID] and 0b111).toInt()
            val shotCounter2: Int = (data[RECOIL_OFFSET_HIT_BY2_SHOTID] and 0b111).toInt()
            val sensorsHit = data[RECOIL_OFFSET_SENSORS_HIT_BITMASK].toInt()
            val sensorsHit2 = data[RECOIL_OFFSET_SENSORS_HIT_BITMASK_2].toInt()
            if (shotById1 != 0) {
                /* We can not use a PlayerId of 0 because it is the default for shotById1 and shotById2.
                It is impossible to distinguish a real shot by this player from regular telemetry data
                any time that shotCounter rolls back to 0.
                shotById2 is only non-zero if the gun recieves 2 shots at the same time and thus
                shotById1 will also have to be non-zero. */
                GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_shot_data", arrayOf<Any>(shotById1, shotCounter1, shotById2, shotCounter2, sensorsHit, sensorsHit2))
                logger("sensorsHit = " + sensorsHit + "  | sensorsHit2 = " + sensorsHit2, 1
            }
            val shotsRemaining: Int = data[RECOIL_OFFSET_SHOTS_REMAINING].toInt() and 0xFF
            if (shotsRemaining != trackedShotsRemaining) {
                trackedShotsRemaining = shotsRemaining
                GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_shotsRemaining", arrayOf<Any>(trackedShotsRemaining))
            }
            val status = data[RECOIL_OFFSET_STATUS].toInt()
            val playerIdAccepted = data[RECOIL_OFFSET_PLAYER_ID_ACCEPT].toInt()
            /* Just to be clear the Weapon Profile below is the guns current profile.
               Where as the above Weapon Profiles are the one for the shooter that
               has shot you. */
            val wpnProfileAgain = data[RECOIL_OFFSET_WEAPON_PROFILE].toInt()
            /* Commented out until we are ready to implement it.
            logger("status = " + status + "  | playerIdAccepted = " +
                playerIdAccepted + "  | wpnProfileAgain = " +
                wpnProfileAgain, 1);
            */
            // TODO: Grenade Pairing.
        }
    }

    /* Android callbacks. */
    private var anyLeScanCallbacks: ScanCallback? = null

    // Handles various events fired by the BLE Service.
    private val mGattUpdateReceiver: BroadcastReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val action = intent.action
            if (BluetoothLeService.ACTION_GATT_CONNECTED == action) {
                GodotLib.calldeferred(instanceId.toLong(), "_on_laser_gun_connected", arrayOf())
            } else if (BluetoothLeService.ACTION_GATT_DISCONNECTED == action) {
                //GodotLib.calldeferred(instanceId, "_on_laser_gun_disconnected", new Object[]{});
                //This is called too often to be reliable even when the device is still connected.
            } else if (BluetoothLeService.ACTION_GATT_SERVICES_DISCOVERED == action) {
                // Show all the supported services and characteristics on the user interface.
                //displayGattServices(mBluetoothLeService.getSupportedGattServices());
                //logger("Services discovered!", 1);
                //GodotLib.calldeferred(instanceId, "_on_laser_gun_connected", new Object[]{});
                for (gattService in bluetoothService!!.supportedGattServices!!) {
                    logger("Service: " + gattService.uuid.toString(), 1)
                    if (gattService.uuid.toString() == GattAttributes.RECOIL_MAIN_SERVICE) {
                        logger("Found Recoil Main Service", 1)
                        telemetryCharacteristic = gattService.getCharacteristic(UUID.fromString(GattAttributes.RECOIL_TELEMETRY_UUID))
                        if (telemetryCharacteristic != null) {
                            bluetoothService!!.setCharacteristicNotification(telemetryCharacteristic!!, true)
                            logger("Found Telemetry characteristic.", 1)
                        } else {
                            logger("Failed to find Telemetry characteristic!", 3)
                            return
                        }
                        commandCharacteristic = gattService.getCharacteristic(UUID.fromString(GattAttributes.RECOIL_COMMAND_UUID))
                        configCharacteristic = gattService.getCharacteristic(UUID.fromString(GattAttributes.RECOIL_CONFIG_UUID))
                        val idCharacteristic = gattService.getCharacteristic(UUID.fromString(GattAttributes.RECOIL_ID_UUID))
                        if (idCharacteristic != null) {
                            bluetoothService!!.readCharacteristic(idCharacteristic) // to get the blaster type, rifle or pistol
                            logger("Found ID characteristic.", 1)
                        } else {
                            logger("Failed to find ID characteristic!", 3)
                        }
                    }
                }
            } else if (BluetoothLeService.TELEMETRY_DATA_AVAILABLE == action) {
                processTelemetryData()
            } else if (BluetoothLeService.ID_DATA_AVAILABLE == action) {
                laserType = intent.getByteExtra(BluetoothLeService.EXTRA_DATA, BLASTER_TYPE_PISTOL)
                if (laserType == BLASTER_TYPE_RIFLE) {
                    logger("Riffle detected.", 1)
                } else {
                    // We'll automatically assume that this is a pistol
                    logger("Pistol detected.", 1)
                }
            } else if (BluetoothLeService.CHARACTERISTIC_WRITE_FINISHED == action) {
                //TODO: Start Reloading using a timer call to godot for timer.
            }
        }
    }

    /* Godot callbacks you can reimplement, as SDKs often need them */
    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent) {
        if (requestCode == 1) {
            GodotLib.calldeferred(instanceId.toLong(), "_on_activity_result_bt_enable", arrayOf())
        }
    }

    override fun onMainRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        val granted = grantResults.size > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED
        //GodotLib.calldeferred(mInstanceId, "_on_request_premission_result", new Object[]{requestCode, permissions[0], granted});
        if (requestCode == 2) {
            GodotLib.calldeferred(instanceId.toLong(), "_on_activity_result_fine_access", arrayOf())
        }
        logger("Permission: " + requestCode + " | " + permissions[0] + " allowed? " + granted, 1)
    }

    override fun onMainPause() {}
    override fun onMainResume() {}
    override fun onMainDestroy() {}
    override fun onMainCreateView(activity: Activity): View? {
        appActivity = activity
        appContext = appActivity!!.applicationContext
        val view = activity.layoutInflater.inflate(R.layout.freecoil_view, null)
        Log.i(TAG, "Got the appActivity.")
        return view
    }

    override fun onGLDrawFrame(gl: GL10) {}
    override fun onGLSurfaceChanged(gl: GL10, width: Int, height: Int) {} // singletons will always miss first onGLSurfaceChanged call

    companion object {
        /* We run a single handler to check and see if we have connected to a weapon within 30 seconds */
        private const val CONNECTION_FAIL_TEST_INTERVAL_MILLISECONDS = 30000
        private const val TAG = "FreecoiLKotlinPlugin"
        private var commandId = 0x00.toByte()
        private const val COMMAND_ID_INCREMENT = 0x10.toByte()
        private const val BLASTER_TYPE_PISTOL = 2.toByte()
        private const val BLASTER_TYPE_RIFLE = 1.toByte()
        private var laserType = BLASTER_TYPE_PISTOL
        const val SHOT_MODE_FULL_AUTO = 1
        const val SHOT_MODE_SINGLE = 2
        const val SHOT_MODE_BURST = 4
        const val FIRING_MODE_OUTDOOR_NO_CONE = 0
        const val FIRING_MODE_OUTDOOR_WITH_CONE = 1
        const val FIRING_MODE_INDOOR_NO_CONE = 2

        /* COMMAND_ID is only the first nibble, second nibble is continous counter.*/
        const val RECOIL_OFFSET_COMMAND_ID = 0
        const val RECOIL_OFFSET_PLAYER_ID = 1
        const val RECOIL_OFFSET_BUTTONS_BITMASK = 2
        const val RECOIL_OFFSET_RELOAD_TRIGGER_COUNTER = 3
        const val RECOIL_OFFSET_THUMB_COUNTER = 4
        const val RECOIL_OFFSET_POWER_COUNTER = 5
        const val RECOIL_OFFSET_LOW_ORDER_BATTERY_LEVEL = 6
        const val RECOIL_OFFSET_BATTERY_LEVEL = 7
        const val RECOIL_OFFSET_HIT_BY1_SHOTID = 8
        const val RECOIL_OFFSET_HIT_BY1 = 9
        const val RECOIL_OFFSET_SENSORS_HIT_BITMASK = 10
        const val RECOIL_OFFSET_HIT_BY2_SHOTID = 11
        const val RECOIL_OFFSET_HIT_BY2 = 12
        const val RECOIL_OFFSET_SENSORS_HIT_BITMASK_2 = 13
        const val RECOIL_OFFSET_SHOTS_REMAINING = 14
        const val RECOIL_OFFSET_STATUS = 15
        const val RECOIL_OFFSET_PLAYER_ID_ACCEPT = 16
        const val RECOIL_OFFSET_WEAPON_PROFILE = 17
        const val RECOIL_TRIGGER_BIT = 0x01
        const val RECOIL_RELOAD_BIT = 0x02
        const val RECOIL_THUMB_BIT = 0x04
        const val RECOIL_POWER_BIT = 0x10
        private const val WEAPON_PROFILE = 0x00.toByte()
        private const val HELLO_WORLD = "Hello New World from FreecoiL Kotlin"
        private fun makeGattUpdateIntentFilter(): IntentFilter {
            val intentFilter = IntentFilter()
            intentFilter.addAction(BluetoothLeService.ACTION_GATT_CONNECTED)
            intentFilter.addAction(BluetoothLeService.ACTION_GATT_DISCONNECTED)
            intentFilter.addAction(BluetoothLeService.ACTION_GATT_SERVICES_DISCOVERED)
            intentFilter.addAction(BluetoothLeService.TELEMETRY_DATA_AVAILABLE)
            intentFilter.addAction(BluetoothLeService.ID_DATA_AVAILABLE)
            intentFilter.addAction(BluetoothLeService.CHARACTERISTIC_WRITE_FINISHED)
            return intentFilter
        }
    }

    init {
        anyLeScanCallbacks = object : ScanCallback() {
            override fun onScanResult(callbackType: Int, result: ScanResult) {
                super.onScanResult(callbackType, result)
                checkDeviceName(result.device)
            }

            override fun onBatchScanResults(results: List<ScanResult>) {
                super.onBatchScanResults(results)
                for (result in results) {
                    if (checkDeviceName(result.device)) return
                }
            }

            override fun onScanFailed(errorCode: Int) {
                super.onScanFailed(errorCode)
                logger("Bluetooth Scan Failed with error code: " + Integer.toString(errorCode), 3)
            }

            private fun checkDeviceName(device: BluetoothDevice): Boolean {
                if (device.name != null && !device.name.isEmpty()) {
                    if (btDeviceAddress.isEmpty() && device.name.startsWith("SRG1") || btDeviceAddress == device.address) {
                        logger("Connecting to " + device.name + " '" + device.address + "'", 1)
                        //TODO: Godot Callback set status to connecting to gun.
                        bluetoothScanner!!.stopScan(anyLeScanCallbacks)
                        bluetoothScanning = false
                        btDeviceAddress = device.address
                        setupBLEServiceConnection()
                        return true
                    }
                }
                return false
            }
        }
    }
    /* **********************************************************************
     * Definitions
     * ********************************************************************** */
    /**
     * Constructor
     */
    init {
        Log.i(TAG, "FreecoiL Plugin is being constructed.")
        //this.appContext = godot.getApplicationContext();
        appInstance = this
        Log.i(TAG, "Construction complete.")
    }
}
