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

import android.Manifest
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
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.location.Location
import android.location.LocationManager
import android.os.*
import android.provider.Settings
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.feralbytes.games.freecoilkotlin.BluetoothLeService.LocalBinder
import com.google.android.gms.location.*
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.SupportMapFragment
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.MarkerOptions
import org.godotengine.godot.Godot
import org.godotengine.godot.GodotLib
import org.godotengine.godot.plugin.GodotPlugin
import java.util.*
import java.util.concurrent.TimeUnit
import javax.microedition.khronos.opengles.GL10
import kotlin.experimental.and

//import androidx.fragment.app.FragmentActivity;
class FreecoiLPlugin(godot: Godot?) : GodotPlugin(godot) {
    var appActivity: Activity? = null
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
    /* */
    @Volatile
    private var playerId = 0
    @Volatile
    private var commandId = 0
    @Volatile
    private var shotsRemaining = 0
    private val trackedHitById1 = 0
    private val trackedHitById2 = 0
    @Volatile
    private var triggerBtnCounter = 0
    @Volatile
    private var reloadBtnCounter = 0
    @Volatile
    private var thumbBtnCounter = 0
    @Volatile
    private var powerBtnCounter = 0
    @Volatile
    private var batteryLvlHigh = 0
    @Volatile
    private var batteryLvlLow = 0
    @Volatile
    private var buttonsPressed = 0
    private val trackedShotId1 = 0
    private val trackedShotId2 = 0
    /* **********************************************************************
     * GPS Vars
     * ********************************************************************** */
    private lateinit var myFusedLocationProviderClient: FusedLocationProviderClient
    private lateinit var myLocationRequest: LocationRequest
    private var myCurrentBestLocation: Location? = null
    private lateinit var  myLocationManager: LocationManager
    private lateinit var myLocationCallback: LocationCallback
    private val sUINTERVAL = (2 * 1000).toLong()  /* 10 secs */
    private val sFINTERVAL: Long = 2000 /* 2 sec */
    private lateinit var locationManager: LocationManager


    /* **********************************************************************
     * Public Methods
     * ********************************************************************** */
    override fun getPluginName(): String {
        return "FreecoiL"
    }

    override fun getPluginMethods(): List<String> {
        return Arrays.asList("hello", "init", "bluetoothStatus",
                "enableBluetooth", "fineAccessPermissionStatus", "requestFineAccess", "startBluetoothScan",
                "stopBluetoothScan", "vibrate", "setLaserId", "startReload", "finishReload", "setShotMode",
                "enableRecoil", "finishInit", "enableLocation", "cellLocationStatus", "gpsLocationStatus",
                "getLastLocation")
    }

    fun hello(): String {
        Log.i(TAG, "FreecoiL Kotlin Plugin: Version: " + FREECOIL_VERSION)
        return HELLO_WORLD
    }

    fun init(pInstanceId: Int) {
        if (!initialized) {
            instanceId = pInstanceId
            GodotLib.calldeferred(instanceId.toLong(), "_on_mod_init", arrayOf())
            logger("FreecoiL Kotlin module initialized.", 1)
            initialized = true
        }
    }

    fun finishInit() {
        bluetoothService = BluetoothLeService()
        if (!bluetoothService!!.initialize(appInstance)) {
            logger("Unable to initialize Bluetooth Low Energy Service!", 4)
        }
        vibrator = appContext!!.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        myLocationRequest = LocationRequest().apply {
            interval = TimeUnit.MILLISECONDS.toMillis(500)
            fastestInterval = TimeUnit.SECONDS.toMillis(2)
            maxWaitTime = TimeUnit.MINUTES.toMillis(2)
            priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        }
        myLocationCallback = theLocationCallback
        myFusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(appActivity!!)
        myLocationManager = appContext!!.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (ActivityCompat.checkSelfPermission(appActivity!!, Manifest.permission.ACCESS_FINE_LOCATION) != PERMISSION_GRANTED && ActivityCompat.checkSelfPermission(
                        appActivity!!, Manifest.permission.ACCESS_COARSE_LOCATION) != PERMISSION_GRANTED) {
            // TODO: Consider calling
            //    ActivityCompat#requestPermissions
            // here to request the missing permissions, and then overriding
            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //                                          int[] grantResults)
            // to handle the case where the user grants the permission. See the documentation
            // for ActivityCompat#requestPermissions for more details.
            return
        }
        else {
            //Looper.prepare()
            myFusedLocationProviderClient.requestLocationUpdates(myLocationRequest, myLocationCallback, Looper.getMainLooper())
        }
        GodotLib.calldeferred(instanceId.toLong(), "_on_mod_finished_init", arrayOf())
    }

    fun requestFineAccess() {
        if (ActivityCompat.shouldShowRequestPermissionRationale(appActivity!!, Manifest.permission.ACCESS_FINE_LOCATION)) {
            val permisionStr = arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
            ActivityCompat.requestPermissions(appActivity!!,
                    permisionStr,
                    3)
        } else {
            val permisionStr = arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
            ActivityCompat.requestPermissions(appActivity!!,
                    permisionStr,
                    1)

        }
    }

    fun fineAccessPermissionStatus(): Boolean {
        if (ContextCompat.checkSelfPermission(appActivity!!, Manifest.permission.ACCESS_FINE_LOCATION) != PERMISSION_GRANTED) {
            logger("Permission is currently denied for: ACCESS_FINE_LOCATION.", 1)
            return false
        }
        else {
            return true
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
        else if (bluetoothAdapter!!.isEnabled) {
            //bluetoothManager = appContext!!.getSystemService(Context.BLUETOOTH_SERVICE)!! as BluetoothManager
            bluetoothScanner = bluetoothAdapter!!.bluetoothLeScanner
            if (bluetoothScanner == null) {
                logger("Failed to to set up Bluetooth Low Energy Scanner.!", 4)
                return 2  // 2 == An error setting up Bluetooth.
            }
            return 1  // 0 == Bluetooth is On/Enabled.
        }
        else {
            return 0  // 0 == Bluetooth is Off/Disabled.
        }
    }

    fun gpsLocationStatus(): Boolean {
        return myLocationManager!!.isProviderEnabled(LocationManager.GPS_PROVIDER)
    }

    fun cellLocationStatus(): Boolean {
        return myLocationManager!!.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    fun enableBluetooth() {
        val intentBtEnabled = Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE)
        /* The REQUEST_ENABLE_BT constant passed to startActivityForResult() is a locally defined integer
               (which must be greater than 0), that the system passes back to you in your onActivityResult()
               implementation as the requestCode parameter. */
        appActivity!!.startActivityForResult(intentBtEnabled, 2)
        return
    }

    fun enableLocation() {
        val intentBtEnabled = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
        /* The REQUEST_ENABLE_BT constant passed to startActivityForResult() is a locally defined integer
               (which must be greater than 0), that the system passes back to you in your onActivityResult()
               implementation as the requestCode parameter. */
        appActivity!!.startActivityForResult(intentBtEnabled, 4)
        return
    }

    fun getLastLocation() {
        if (ActivityCompat.checkSelfPermission(appContext!!, Manifest.permission.ACCESS_FINE_LOCATION) != PERMISSION_GRANTED
                && ActivityCompat.checkSelfPermission(appContext!!, Manifest.permission.ACCESS_COARSE_LOCATION) != PERMISSION_GRANTED) {
            // TODO: Consider calling
            //    ActivityCompat#requestPermissions
            // here to request the missing permissions, and then overriding
            //   public void onRequestPermissionsResult(int requestCode, String[] permissions,
            //                                          int[] grantResults)
            // to handle the case where the user grants the permission. See the documentation
            // for ActivityCompat#requestPermissions for more details.
            return
        }
        myFusedLocationProviderClient!!.lastLocation.addOnSuccessListener { location: Location? ->
            if (location != null) {
                GodotLib.calldeferred(instanceId.toLong(), "_last_location_test", arrayOf(location.accuracy, location.toString()))
            }
        }
    }

    fun startBluetoothScan() {
        logger("Starting Bluetooth scan", 2)
        bluetoothScanner!!.startScan(anyLeScanCallbacks)
        bluetoothScanning = true
    }

    fun stopBluetoothScan() {
        bluetoothScanner!!.stopScan(anyLeScanCallbacks)
    }

    private fun vibrate(durationMillis: Int) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator!!.vibrate(VibrationEffect.createOneShot(durationMillis.toLong(), VibrationEffect.DEFAULT_AMPLITUDE))
        }
        else {
            @Suppress("DEPRECATION")  //Depreciated in API 26
            vibrator!!.vibrate(durationMillis.toLong())
        }
    }

    fun setLaserId(newPlayerId: Int) {
        playerId = newPlayerId
        val command = ByteArray(20)
        commandId += COMMAND_ID_INCREMENT
        command[0] = commandId.toByte()
        command[2] = 0x80.toByte()
        command[4] = playerId.toByte()
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
        commandId += COMMAND_ID_INCREMENT
        command[0] = commandId.toByte()
        command[2] = 0x02.toByte() // Start reload.
        command[4] = 0.toByte()  // Resetting the ID to 0 seems to make ID changes reliable.
        /*command[5] = WEAPON_PROFILE; // changing profiles during the first stage of reload doesn't
          really do anything since the blaster can't shoot in this state anyway*/commandCharacteristic!!.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        commandCharacteristic!!.value = command
        bluetoothService!!.writeCharacteristic(commandCharacteristic!!)
    }

    /* Second stage of the reload commands which tells the tagger how many shots to load and allows
       it to shoot again. Command format is 00 00 04 00 PLAYER_ID 00 SHOT_COUNT and then 0 filled. */
    fun finishReload(magazine: Int, newPlayerId: Int, wpnPrfl: Int = WEAPON_PROFILE.toInt()) {
        if (commandCharacteristic == null || bluetoothService == null) return
        logger("Finishing reloading.", 1)
        val command = ByteArray(20)
        commandId +=COMMAND_ID_INCREMENT
        command[0] = commandId.toByte()
        command[2] = 0x04.toByte() // Finish reload.
        if (newPlayerId == playerId) {
            command[4] = playerId.toByte()
        }
        else {
            command[4] = newPlayerId.toByte()
        }
        command[5] = wpnPrfl.toByte()
        command[6] = magazine.toByte() // Is the size of a reload.
        commandCharacteristic!!.writeType = BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT
        commandCharacteristic!!.value = command
        bluetoothService!!.writeCharacteristic(commandCharacteristic!!)
    }

    /* Config 00 00 09 xx yy ff c8 ff ff 80 01 34 - xx is the number of shots and if you set yy to 01 for
       full auto for xx shots or 00 for single shot mode, increasing yy decreases Rate of Fire.
       Setting 03 03 for shots and Rate of Fire will give a good 3 shot burst, 03 01 is so fast that you
       only feel 1 recoil for 3 shots */
    fun setShotMode(shotMode: Int, narrowBeamLaserPwr: Int, wideBeamLaserPwr: Int, customRateOfFire: Int = 0) {
        if (configCharacteristic == null || bluetoothService == null) return
        val config = ByteArray(20)
        config[0] = WEAPON_PROFILE
        config[2] = 0x09.toByte()
        config[7] = 0xFF.toByte()
        config[8] = 0xFF.toByte()
        config[9] = 0x80.toByte() // Recoil strength
        config[10] = 0x02.toByte()
        config[11] = 0x34.toByte()
        Log.i(TAG, "fun setShotMode(): $shotMode $customRateOfFire")
        if (shotMode == SHOT_MODE_SINGLE) {
            config[3] = 0xFE.toByte()
            config[4] = 0x00.toByte()
        }
        else if (shotMode == SHOT_MODE_BURST) {
            config[3] = 0x03.toByte()
            config[4] = 0x03.toByte()
            if (laserType == BLASTER_TYPE_RIFLE) config[9] = 0x78.toByte() // Reduce rifle recoil strength to allow 3 recoils to occur in time.
        }
        else if (shotMode == SHOT_MODE_FULL_AUTO) {
            config[3] = 0xFE.toByte()
            config[4] = 0x01.toByte()
        }
        else {
            config[3] = 0xFE.toByte()
            config[4] = customRateOfFire.toByte()
        }
        config[5] = narrowBeamLaserPwr.toByte()
        config[6] = wideBeamLaserPwr.toByte()
        /* Original Defaults Below.
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
        }*/
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

    fun status133Bug() {
        GodotLib.calldeferred(instanceId.toLong(), "_status_133_bug", arrayOf())
    }

    private fun setupBLEServiceConnection() {
        BLEServiceConnection = object : ServiceConnection {
            override fun onServiceConnected(componentName: ComponentName, service: IBinder) {
                bluetoothService = (service as LocalBinder).service
                if (!bluetoothService!!.initialize(appInstance)) {
                    logger("Unable to initialize Bluetooth LE Service!", 5)
                    //finish();
                }
                else {
                    // Automatically connects to the device upon successful start-up initialization.
                    appActivity!!.runOnUiThread { bluetoothService!!.connect(btDeviceAddress) }
                    // TODO: Send Godot the new perfered laser Tagger for reconnects.
                }
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
            val continuousCounter: Int = (data[TELEM_COMMAND_ID_N_COUNTER] and 0x0F.toByte()).toInt()
            val telemetryCommandId: Int = (data[TELEM_COMMAND_ID_N_COUNTER].toInt() shr 4 and 0b1111).toInt()
            playerId = data[TELEM_PLAYER_ID].toInt()
            /*GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_playerId", arrayOf<Any>(playerId))*/
            buttonsPressed = data[TELEM_BUTTONS_PRESSED].toInt()
            val powerBtnPressed = buttonsPressed shr 4
            val triggerBtnPressed = buttonsPressed and 0b1
            val thumbBtnPressed = buttonsPressed shr 1 and 0b1
            val reloadBtnPressed = buttonsPressed shr 2 and 0b1
            /*GodotLib.calldeferred(instanceId.toLong(), "_changed_telem_button_pressed", arrayOf<Any>(powerBtnPressed, triggerBtnPressed, thumbBtnPressed, reloadBtnPressed))*/
            /* Rather than monitor if a button is currently pressed, we monitor the counter. Usually
               when the player presses a button, we see many packets showing that the button is
               pressed. We don't want to toggle recoil or modes with every packet we receive so it
               makes more sense to just monitor when the counter changes so we can toggle exactly
               once each time that button is pressed. */
            triggerBtnCounter = data[TELEM_TRIGGER_N_RELOAD_COUNTER].toInt() and 0b1111  // Messed With
            /*GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_triggerBtnCounter", arrayOf<Any>(triggerBtnCounter))*/
            /* NOTE: Below is a conversion performed on the 1st nibble (last/low 4-bits/ least significant) to make it act
            * as a proper 4-bit int which counts 0-15. */
            reloadBtnCounter = (data[TELEM_TRIGGER_N_RELOAD_COUNTER].toInt() shr 4 and 0b1111).toInt()
            /*GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_reloadBtnCounter", arrayOf<Any>(reloadBtnCounter))*/
            thumbBtnCounter = data[TELEM_THUMB_COUNTER].toInt()
            /*GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_thumbBtnCounter", arrayOf<Any>(thumbBtnCounter))*/
            powerBtnCounter = data[TELEM_POWER_COUNTER].toInt()
            /*GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_powerBtnCounter", arrayOf<Any>(powerBtnCounter))*/
            batteryLvlLow = data[TELEM_BATTERY_LEVEL_LOW_ORDER].toInt()
            batteryLvlHigh = data[TELEM_BATTERY_LEVEL_HIGH_ORDER].toInt()
            /*GodotLib.calldeferred(instanceId.toLong(), "_laser_telem_batteryLvl", arrayOf<Any>(batteryLvlHigh))*/
            /* bytes are always signed in Java and if you don't do "& 0xFF" here, you will get
               negative numbers in the hitById# field when using player IDs > 32 */
            /* shooter1LaserId defaults to 0 and a shot counter of 0. So using a player ID of 0 would
               result in missing every 8th shot even with complex logic.
               shooter1LaserId is only the left most or most significant 6 bytes. So a max of 0-63.
               So 63 players max, because we do not use 0 since it is default for no shot.*/
            val shooter1LaserId: Int = data[TELEM_SHOOTER_1_LASER_ID_N_WPN].toInt() shr 2 and 0b111111
            val shooter2LaserId: Int = data[TELEM_SHOOTER_2_LASER_ID_N_WPN].toInt() shr 2 and 0b111111
            /* The 2 least significant bits of TELEM_SHOOTER_1_LASER_ID_N_WPN are the
                2 most significant bits of the weapon profile ID*/
            val shooter1WpnProfileMost: Int = data[TELEM_SHOOTER_1_LASER_ID_N_WPN].toInt() and 0b11
            val shooter2WpnProfileMost: Int = data[TELEM_SHOOTER_2_LASER_ID_N_WPN].toInt() and 0b11
            val shooter1WpnProfileLeast: Int = data[TELEM_SHOOTER_1_WPN_N_CHARGE].toInt() shr 6 and 0b11  // Messed With
            val shooter1charge: Int = data[TELEM_SHOOTER_1_WPN_N_CHARGE].toInt() shr 3 and 0b111
            val shooter1check: Int = data[TELEM_SHOOTER_1_WPN_N_CHARGE].toInt() and 0b111  // Messed With
            val shooter2WpnProfileLeast: Int = data[TELEM_SHOOTER_2_WPN_N_CHARGE].toInt() and 0b11
            val shooter2charge: Int = data[TELEM_SHOOTER_2_WPN_N_CHARGE].toInt() shr 3 and 0b111
            val shooter2check: Int = data[TELEM_SHOOTER_2_WPN_N_CHARGE].toInt() shr 5 and 0b111
            val shooter1WpnProfile = (shooter1WpnProfileMost shl 2) + shooter1WpnProfileLeast  // Messed With
            val shooter2WpnProfile = (shooter2WpnProfileMost shl 2) + shooter2WpnProfileLeast  // Messed With
            val shotCounter1: Int = data[TELEM_SENSORS_1_N_HIT_COUNTER].toInt() and 0b1111
            val shotCounter2: Int = data[TELEM_SENSORS_2_N_HIT_COUNTER].toInt() and 0b1111
            /*val sensorsNHit: Int = data[TELEM_SENSORS_1_N_HIT_COUNTER].toInt()
            val bit0: Int = sensorsNHit and 0b1
            val bit1: Int = sensorsNHit shr 1 and 0b1
            val bit2: Int = sensorsNHit shr 2 and 0b1
            val bit3: Int = sensorsNHit shr 3 and 0b1
            val bit4: Int = sensorsNHit shr 4 and 0b1
            val bit5: Int = sensorsNHit shr 5 and 0b1
            val bit6: Int = sensorsNHit shr 6 and 0b1
            val bit7: Int = sensorsNHit shr 7 and 0b1
            Log.i(TAG, "Sensors N Hit Counter As Bit Field: $bit7 $bit6 $bit5 $bit4 $bit3 $bit2 $bit1 $bit0")*/
            val sensorsHit1 = data[TELEM_SENSORS_1_N_HIT_COUNTER].toInt() shr 4 and 0b1111
            val sensorsHit2 = data[TELEM_SENSORS_2_N_HIT_COUNTER].toInt() shr 4 and 0b1111
            val leftSensor1 = sensorsHit1 and 0b1
            val frontSensor1 = sensorsHit1 shr 1 and 0b1
            val rightSensor1 = sensorsHit1 shr 2 and 0b1
            val clipSensor1 = sensorsHit1 shr 3 and 0b1
            val leftSensor2 = sensorsHit2 and 0b1
            val frontSensor2 = sensorsHit2 shr 1 and 0b1
            val rightSensor2 = sensorsHit2 shr 2 and 0b1
            val clipSensor2 = sensorsHit2 shr 3 and 0b1
            /*GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_shot_data", arrayOf<Any>(shooter1LaserId, shotCounter1, shooter2LaserId, shotCounter2, sensorsHit, sensorsHit2))
            logger("sensorsHit = " + sensorsHit + "  | sensorsHit2 = " + sensorsHit2, 1)*/
            shotsRemaining = data[TELEM_AMMO_REMAINING].toInt()
            /*GodotLib.calldeferred(instanceId.toLong(), "_changed_laser_telem_shotsRemaining", arrayOf<Any>(shotsRemaining))*/
            val status = data[TELEM_STATUS_FLAGS].toInt()
            val playerIdAccepted = data[TELEM_PLAYER_ID_ACCEPT].toInt()
            /* Just to be clear the Weapon Profile below is the guns current profile.
               Where as the above Weapon Profiles are the one for the shooter that
               has shot you. */
            val wpnProfileAgain = data[TELEM_WEAPON_PROFILE].toInt()
            /* Commented out until we are ready to implement it.
            logger("status = " + status + "  | playerIdAccepted = " +
                playerIdAccepted + "  | wpnProfileAgain = " +
                wpnProfileAgain, 1);
            */
            // TODO: Grenade Pairing.
            GodotLib.calldeferred(instanceId.toLong(), "_processed_laser_telemetry2", arrayOf<Any>(arrayOf<Any>(
                telemetryCommandId, playerId, buttonsPressed, triggerBtnCounter, reloadBtnCounter,
                thumbBtnCounter, powerBtnCounter, batteryLvlHigh, batteryLvlLow, powerBtnPressed,
                triggerBtnPressed, reloadBtnPressed, thumbBtnPressed, shotsRemaining, shooter1LaserId,
                shooter2LaserId, shooter1WpnProfile, shooter2WpnProfile, shooter1charge, shooter1check,
                shooter2charge, shooter2check, shotCounter1, shotCounter2, sensorsHit1, sensorsHit2,
                clipSensor1, frontSensor1, leftSensor1, rightSensor1, clipSensor2, frontSensor2, leftSensor2,
                rightSensor2, status, playerIdAccepted, wpnProfileAgain, continuousCounter)))
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

    /* GPS & Celular Location Listener */
    private val theLocationCallback:LocationCallback = object: LocationCallback() {
        override fun onLocationResult(newLocationResult: LocationResult?) {
            super.onLocationResult(newLocationResult)
            if (newLocationResult?.lastLocation != null) {
                tryNewLocation(newLocationResult.lastLocation)
            }
        }
    }

    private val myLocationListener: LocationListener = object: LocationListener {
        override fun onLocationChanged(newLocation: Location?) {
            if (newLocation != null) {
                tryNewLocation(newLocation)
            }
        }
    }

    fun tryNewLocation(newLocation: Location?) {
        if (checkIfNewLocationIsBetter(newLocation)) {
            myCurrentBestLocation = newLocation
            GodotLib.calldeferred(instanceId.toLong(), "_last_location_test", arrayOf(myCurrentBestLocation!!.accuracy, myCurrentBestLocation.toString()))
            val locAsString = myCurrentBestLocation.toString()
            logger("Location Update Recieved.  $locAsString", 3);
        }
    }

    fun checkIfNewLocationIsBetter(newLocation: Location?) : Boolean {
        if (myCurrentBestLocation == null) {
            return true
        }
        // Check if the time is newer.
        val timeDelta = newLocation!!.getTime() - myCurrentBestLocation!!.getTime()
        val isSignificantlyNewer = timeDelta > TWO_MINUTES
        val isSignificantlyOlder = timeDelta < -TWO_MINUTES
        val isNewer = timeDelta > 0
        if (isSignificantlyNewer) {
            return true
        }
        else if (isSignificantlyOlder) {
            return false
        }
        else {
            val accuracyDelta = newLocation.getAccuracy() - myCurrentBestLocation!!.getAccuracy()
            val isLessAccurate: Boolean = accuracyDelta > 0
            val isMoreAccurate: Boolean = accuracyDelta < 0
            val isSignificantlyLessAccurate: Boolean = accuracyDelta > 200
            val isFromSameProvider: Boolean = isSameProvider(newLocation.getProvider(), myCurrentBestLocation!!.getProvider())
            if (isMoreAccurate) {
                return true;
            }
            else if (isNewer && !isLessAccurate) {
                return true;
            }
            else if (isNewer && !isSignificantlyLessAccurate && isFromSameProvider) {
                return true;
            }
            return false;
        }
    }

    private fun isSameProvider(provider1: String?, provider2: String?): Boolean {
        return if (provider1 == null) {
            provider2 == null
        }
        else provider1 == provider2
    }
    /* Godot callbacks you can reimplement, as SDKs often need them */
    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == 2) {
            var bluetoothResults = 0
            if (resultCode == -1) {
                bluetoothResults = 1
            }
            GodotLib.calldeferred(instanceId.toLong(), "_on_activity_result_bt_enable", arrayOf(bluetoothResults))
        }
        if (requestCode == 4) {
            var m_locationResults = 0
            GodotLib.calldeferred(instanceId.toLong(), "_on_activity_result_location_enable", arrayOf(resultCode))
        }
    }

    override fun onMainRequestPermissionsResult(requestCode: Int, permissions: Array<String>, grantResults: IntArray) {
        val granted = grantResults.size > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED
        //GodotLib.calldeferred(mInstanceId, "_on_request_premission_result", new Object[]{requestCode, permissions[0], granted});
        if ((requestCode == 1) or (requestCode == 3)) {
            GodotLib.calldeferred(instanceId.toLong(), "_on_fine_access_permission_request", arrayOf(granted))
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
        private const val TAG = "FreecoiLKotlinPlugin"
        private var commandId: Byte = 0x00.toByte()
        private const val COMMAND_ID_INCREMENT = 0x10.toByte()
        private const val BLASTER_TYPE_PISTOL = 2.toByte()
        private const val BLASTER_TYPE_RIFLE = 1.toByte()
        private var laserType = BLASTER_TYPE_PISTOL
        const val SHOT_MODE_FULL_AUTO = 1
        const val SHOT_MODE_SINGLE = 0
        const val SHOT_MODE_BURST = 3
        const val FIRING_MODE_OUTDOOR_NO_CONE = 0
        const val FIRING_MODE_OUTDOOR_WITH_CONE = 1
        const val FIRING_MODE_INDOOR_NO_CONE = 2

        /* COMMAND_ID is only the first nibble, second nibble is continous counter.*/
        const val TELEM_COMMAND_ID_N_COUNTER = 0
        const val TELEM_PLAYER_ID = 1
        const val TELEM_BUTTONS_PRESSED = 2
        const val TELEM_TRIGGER_N_RELOAD_COUNTER = 3
        const val TELEM_THUMB_COUNTER = 4
        const val TELEM_POWER_COUNTER = 5
        const val TELEM_BATTERY_LEVEL_LOW_ORDER = 6
        const val TELEM_BATTERY_LEVEL_HIGH_ORDER = 7
        const val TELEM_SHOOTER_1_WPN_N_CHARGE = 8
        const val TELEM_SHOOTER_1_LASER_ID_N_WPN = 9
        const val TELEM_SENSORS_1_N_HIT_COUNTER = 10
        const val TELEM_SHOOTER_2_WPN_N_CHARGE = 11
        const val TELEM_SHOOTER_2_LASER_ID_N_WPN = 12
        const val TELEM_SENSORS_2_N_HIT_COUNTER = 13
        const val TELEM_AMMO_REMAINING = 14
        const val TELEM_STATUS_FLAGS = 15
        const val TELEM_PLAYER_ID_ACCEPT = 16
        const val TELEM_WEAPON_PROFILE = 17
        const val RECOIL_TRIGGER_BIT = 0x01
        const val RECOIL_RELOAD_BIT = 0x02
        const val RECOIL_THUMB_BIT = 0x04
        const val RECOIL_POWER_BIT = 0x10
        private const val WEAPON_PROFILE = 0x00.toByte()
        private const val HELLO_WORLD = "Hello New World from FreecoiL Kotlin"
        private const val FREECOIL_VERSION = "0.3.1-dev8"
        private const val TWO_MINUTES = 1000 * 60 * 2;
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
                    val devAddess = device.address
                    val devName = device.name
                    logger("$TAG: Found Device: $devName   $devAddess", 0)
                    if (btDeviceAddress.isEmpty() && device.name.startsWith("SRG1") || btDeviceAddress == device.address) {
                        logger("Connecting to " + device.name + " '" + device.address + "'", 1)
                        //TODO: Godot Callback set status to connecting to gun.
                        bluetoothScanner!!.stopScan(anyLeScanCallbacks)
                        bluetoothScanning = false
                        btDeviceAddress = device.address
                        setupBLEServiceConnection()
                        return true
                    }
                    else{
                        logger("$TAG: Ignored found device because it didn't match the previous device.", 0)
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
