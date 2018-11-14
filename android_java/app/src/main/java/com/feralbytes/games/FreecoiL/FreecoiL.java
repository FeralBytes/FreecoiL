package org.godotengine.godot;

import android.Manifest;
import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothGattCharacteristic;
import android.bluetooth.BluetoothGattService;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.BluetoothLeScanner;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.IBinder;
import android.os.Vibrator;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.widget.Toast;

import com.godot.game.R;

import java.util.List;
import java.util.UUID;

import javax.microedition.khronos.opengles.GL10;

public class FreecoiL extends Godot.SingletonBase {
    /* We run a single handler to check and see if we have connected to a weapon within 30 seconds */
    private static final int CONNECTION_FAIL_TEST_INTERVAL_MILLISECONDS = 30000;

    public Activity appActivity;
    public Context appContext;
    public FreecoiL appInstance;

    private int instanceId = 0;
    private boolean initialized;
    private BluetoothAdapter bluetoothAdapter;
    private BluetoothLeService bluetoothService;
    private BluetoothLeScanner bluetoothScanner;
    private BluetoothManager bluetoothManager;
    private static final String TAG = "FreecoiL: Java: ";
    private boolean bluetoothConnected = false;
    private boolean bluetoothScanning = false;
    private Vibrator vibrator = null;
    private String btDeviceAddress = ""; // MAC address of the tagger
    private int toastDisplayLength = 0;

    /* Code specific to BluetoothLeGATT. */
    private ServiceConnection BLEServiceConnection = null;
    private BluetoothGattCharacteristic telemetryCharacteristic = null;
    private BluetoothGattCharacteristic commandCharacteristic = null;
    private BluetoothGattCharacteristic configCharacteristic = null;

    private static byte commandId = (byte) 0x00;
    private static final byte COMMAND_ID_INCREMENT = (byte) 0x10;

    private static final byte BLASTER_TYPE_PISTOL = (byte)2;
    private static final byte BLASTER_TYPE_RIFLE = (byte)1;
    private static byte lazerType = BLASTER_TYPE_PISTOL;
    public static final int SHOT_MODE_FULL_AUTO = 1;
    public static final int SHOT_MODE_SINGLE = 2;
    public static final int SHOT_MODE_BURST = 4;
    public static final int FIRING_MODE_OUTDOOR_NO_CONE = 0;
    public static final int FIRING_MODE_OUTDOOR_WITH_CONE = 1;
    public static final int FIRING_MODE_INDOOR_NO_CONE = 2;

    /* COMMAND_ID is only the first nibble, second nibble is continous counter.*/
    public final static int RECOIL_OFFSET_COMMAND_ID = 0;
    public final static int RECOIL_OFFSET_PLAYER_ID = 1;
    public final static int RECOIL_OFFSET_BUTTONS_BITMASK = 2;
    public final static int RECOIL_OFFSET_RELOAD_TRIGGER_COUNTER = 3;
    public final static int RECOIL_OFFSET_THUMB_COUNTER = 4;
    public final static int RECOIL_OFFSET_POWER_COUNTER = 5;
    public final static int RECOIL_OFFSET_LOW_ORDER_BATTERY_LEVEL = 6;
    public final static int RECOIL_OFFSET_BATTERY_LEVEL = 7;
    public final static int RECOIL_OFFSET_HIT_BY1_SHOTID = 8;
    public final static int RECOIL_OFFSET_HIT_BY1 = 9;
    public final static int RECOIL_OFFSET_SENSORS_HIT_BITMASK = 10;
    public final static int RECOIL_OFFSET_HIT_BY2_SHOTID = 11;
    public final static int RECOIL_OFFSET_HIT_BY2 = 12;
    public final static int RECOIL_OFFSET_SENSORS_HIT_BITMASK_2 = 13;
    public final static int RECOIL_OFFSET_SHOTS_REMAINING = 14;
    public final static int RECOIL_OFFSET_STATUS = 15;
    public final static int RECOIL_OFFSET_PLAYER_ID_ACCEPT = 16;
    public final static int RECOIL_OFFSET_WEAPON_PROFILE = 17;

    public final static int RECOIL_TRIGGER_BIT = 0x01;
    public final static int RECOIL_RELOAD_BIT = 0x02;
    public final static int RECOIL_THUMB_BIT = 0x04;
    public final static int RECOIL_POWER_BIT = 0x10;

    private static final byte WEAPON_PROFILE = (byte)0x00;

    private volatile int trackedPlayerId = 0;
    private volatile int trackedCommandId = 0;
    private volatile int trackedShotsRemaining = 0;
    private volatile int trackedHitById1 = 0;
    private volatile int trackedHitById2 = 0;
    private volatile int trackedTriggerBtnCounter = 0;
    private volatile int trackedReloadBtnCounter = 0;
    private volatile int trackedThumbBtnCounter = 0;
    private volatile int trackedPowerBtnCounter = 0;
    private volatile int trackedBatteryLvl = 0;
    private volatile int trackedShotId1 = 0;
    private volatile int trackedShotId2 = 0;


    /* **********************************************************************
     * Public Methods
     * ********************************************************************** */

    public void init(int pInstanceId) {
        if (!initialized) {
            instanceId = pInstanceId;
            bluetoothService = new BluetoothLeService();
            if (!bluetoothService.initialize(appInstance)) {
                logger("Unable to initialize BluetoothLeService!", 4);
            }
            vibrator = (Vibrator) appContext.getSystemService(Context.VIBRATOR_SERVICE);
            GodotLib.calldeferred(instanceId, "_on_mod_init", new Object[]{});
            logger("FreecoiL module initialized.", 1);
            initialized = true;
        }
    }

    public int bluetoothStatus() {
        /* Must Initialize a Bluetooth adapter for API 18+.*/
        bluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        // Checks if Bluetooth is supported on the device.
        if (bluetoothAdapter == null) {
            logger("Error: Bluetooth not supported!", 4);
            //finish();
            return 2;  // Error Code for Bluetooth Not Supported.
        }
        if (bluetoothAdapter.isEnabled()) {
            bluetoothManager = (BluetoothManager) appContext.getSystemService(Context.BLUETOOTH_SERVICE);
            bluetoothScanner = bluetoothAdapter.getBluetoothLeScanner();
            return 1;
        }
        else {
            return 0;
        }
    }

    public void enableBluetooth() {
        Intent intentBtEnabled = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            /* The REQUEST_ENABLE_BT constant passed to startActivityForResult() is a locally defined integer
               (which must be greater than 0), that the system passes back to you in your onActivityResult()
               implementation as the requestCode parameter. */
        int REQUEST_ENABLE_BT = 1;
        appActivity.startActivityForResult(intentBtEnabled, REQUEST_ENABLE_BT);
        return;
    }

    public int fineAccessPermissionStatus() {
        /* Need to make sure that we have permission for FINE_LOCATION_ACCESS Although only Coarse
           is needed for bluetooth. But we will need fine for gps latter. */
        if (ContextCompat.checkSelfPermission(appActivity, Manifest.permission.ACCESS_FINE_LOCATION)
                != PackageManager.PERMISSION_GRANTED) {
            // Permission is not granted
            logger("Permission is currently denied for: ACCESS_FINE_LOCATION.", 1);
            return 0;
        }
        else {
            return 1;
        }
    }

    public void enableFineAccess() {
        // Should we show an explanation?
        if (ActivityCompat.shouldShowRequestPermissionRationale(appActivity,
                Manifest.permission.ACCESS_FINE_LOCATION)) {
            // Show an explanation to the user *asynchronously* -- don't block
            // this thread waiting for the user's response! After the user
            // sees the explanation, try again to request the permission.
            // TODO: Make a callback to show the rational.
        }
        else {
            // No explanation needed; request the permission
            int PERMISSIONS_REQUEST_ACCESS_FINE_LOCATION = 2;
            ActivityCompat.requestPermissions(appActivity,
                    new String[]{Manifest.permission.ACCESS_FINE_LOCATION},
                    PERMISSIONS_REQUEST_ACCESS_FINE_LOCATION);
        }
    }

    public void startBluetoothScan() {
        if (bluetoothManager == null) {
            logger("Failed to get Bluetooth service", 4);
            return;
        }
        logger("Starting Bluetooth scan", 1);
        bluetoothScanner.startScan(anyLeScanCallbacks);
        bluetoothScanning = true;
    }

    public void stopBluetoothScan() {
        bluetoothScanner.stopScan(anyLeScanCallbacks);
    }

    private void vibrate(final int durationMillis) {
        vibrator.vibrate(durationMillis);
    }

    public void setLazerId(final int player_id) {
        trackedPlayerId = player_id;
        byte[] command = new byte[20];
        commandId += COMMAND_ID_INCREMENT;
        command[0] = commandId;
        command[2] = (byte) 0x80;
        command[4] = (byte) trackedPlayerId;
        commandCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        commandCharacteristic.setValue(command);
        bluetoothService.writeCharacteristic(commandCharacteristic);
    }

    /* Initial reload command that tells the tagger not to shoot anymore (or maybe it just sets the
       remaining shot counter to 0). It also sets the tagger in what I guess is status 0x03 instead
       of the usual 0x02. The command format is F0 00 02 00 PLAYER_ID and then 0 filled to the end. */
    public void startReload() {
        if (commandCharacteristic == null || bluetoothService == null)
            return;
        logger("Started reloading.", 1);
        byte[] command = new byte[20];
        commandId += COMMAND_ID_INCREMENT;
        command[0] = commandId;
        command[2] = (byte)0x02;  // Start reload.
        command[4] = (byte) trackedPlayerId;
        /*command[5] = WEAPON_PROFILE; // changing profiles during the first stage of reload doesn't
          really do anything since the blaster can't shoot in this state anyway*/
        commandCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        commandCharacteristic.setValue(command);
        bluetoothService.writeCharacteristic(commandCharacteristic);
    }

    /* Second stage of the reload commands which tells the tagger how many shots to load and allows
       it to shoot again. Command format is 00 00 04 00 PLAYER_ID 00 SHOT_COUNT and then 0 filled. */
    public void finishReload(int magazine) {
        if (commandCharacteristic == null || bluetoothService == null )
            return;
        logger("Finishing reloading.", 1);
        byte[] command = new byte[20];
        commandId += COMMAND_ID_INCREMENT;
        command[0] = commandId;
        command[2] = (byte)0x04;  // Finish reload.
        command[4] = (byte) trackedPlayerId;
        command[5] = WEAPON_PROFILE;
        command[6] = (byte) magazine;  // Is the size of a reload.
        commandCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        commandCharacteristic.setValue(command);
        bluetoothService.writeCharacteristic(commandCharacteristic);
    }

    /* Config 00 00 09 xx yy ff c8 ff ff 80 01 34 - xx is the number of shots and if you set yy to 01 for
       full auto for xx shots or 00 for single shot mode, increasing yy decreases Rate of Fire.
       Setting 03 03 for shots and Rate of Fire will give a good 3 shot burst, 03 01 is so fast that you
       only feel 1 recoil for 3 shots */
    public void setShotMode(int shotMode, int firingMode) {
        if (configCharacteristic == null || bluetoothService == null)
            return;
        byte[] config = new byte[20];
        config[0]  = WEAPON_PROFILE;
        config[2]  = (byte)0x09;
        config[7]  = (byte)0xFF;
        config[8]  = (byte)0xFF;
        config[9]  = (byte)0x80;  // Recoil strength
        config[10] = (byte)0x02;
        config[11] = (byte)0x34;
        if (shotMode == SHOT_MODE_SINGLE) {
            config[3] = (byte)0xFE;
            config[4] = (byte)0x00;
        }
        else if (shotMode == SHOT_MODE_BURST) {
            config[3] = (byte)0x03;
            config[4] = (byte)0x03;
            if (lazerType == BLASTER_TYPE_RIFLE)
                config[9] = (byte)0x78; // Reduce rifle recoil strength to allow 3 recoils to occur in time.
        }
        else if (shotMode == SHOT_MODE_FULL_AUTO) {
            config[3] = (byte)0xFE;
            config[4] = (byte)0x01;
        }
        switch (firingMode) {
            case FIRING_MODE_OUTDOOR_NO_CONE:  // int = 0
                config[5]  = (byte)0xFF;
                config[6]  = (byte)0x00;
                break;
            case FIRING_MODE_OUTDOOR_WITH_CONE:  // int = 1
                config[5]  = (byte)0xFF;
                config[6]  = (byte)0xC8;
                break;
            case FIRING_MODE_INDOOR_NO_CONE:  // int = 2
                config[5]  = (byte)0x19;
                config[6]  = (byte)0x00;
        }
        configCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        configCharacteristic.setValue(config);
        bluetoothService.writeCharacteristic(configCharacteristic);
    }

    /* Config 10 00 02 02 ff and 15 sets of 00 disables recoil
       Config 10 00 02 03 ff and 15 sets of 00 enables recoil */
    public void enableRecoil(boolean enabled) {
        if (configCharacteristic == null || bluetoothService == null)
            return;
        byte[] config = new byte[20];
        config[0]  = (byte)0x10;
        config[2]  = (byte)0x02;
        config[4]  = (byte)0xFF;
        if (enabled) {
            config[3] = (byte)0x03;
        }
        else {
            config[3] = (byte)0x02;
        }
        configCharacteristic.setWriteType(BluetoothGattCharacteristic.WRITE_TYPE_DEFAULT);
        configCharacteristic.setValue(config);
        bluetoothService.writeCharacteristic(configCharacteristic);
    }


    /* **********************************************************************
     * Private Methods
     * ********************************************************************** */
    private void makeToast(final String message, boolean displayLong) {

        if (displayLong) {
            toastDisplayLength = Toast.LENGTH_LONG;
        }
        else {
            toastDisplayLength = Toast.LENGTH_SHORT;
        }
        appActivity.runOnUiThread(new Runnable() {
                @Override
                public void run() {
                    Toast.makeText(appActivity, message, toastDisplayLength).show();
                }
        });
    }

    public void logger(final String message, int level) {
        /* Debug Levels:
           0 = debug
           1 = info
           2 = warning
           3 = error
           4 = critical
           5 = exception */
        GodotLib.calldeferred(instanceId, "_new_status", new Object[]{TAG + message, level});
        if (level >= 2) {
            makeToast(message, true);
        }
    }

    private void setupBLEServiceConnection() {
        BLEServiceConnection = new ServiceConnection() {
            @Override
            public void onServiceConnected(ComponentName componentName, IBinder service) {
                bluetoothService = ((BluetoothLeService.LocalBinder) service).getService();
                if (!bluetoothService.initialize(appInstance)) {
                    logger("Unable to initialize Bluetooth LE Service!", 5);
                    //finish();
                }
                // Automatically connects to the device upon successful start-up initialization.
                appActivity.runOnUiThread(new Runnable() {
                    @Override
                    public void run() {
                        bluetoothService.connect(btDeviceAddress);
                    }
                });
                // TODO: Send Godot the new perfered Lazer Tagger for reconnects.
            }

            @Override
            public void onServiceDisconnected(ComponentName componentName) {
                bluetoothService = null;
            }
        };
        bluetoothService.initialize(appInstance);
        appActivity.runOnUiThread(new Runnable() {
            @Override
            public void run() {
                bluetoothService.connect(btDeviceAddress);
            }
        });
        Intent gattServiceIntent = new Intent(appActivity.getBaseContext(), BluetoothLeService.class);
        appContext.registerReceiver(mGattUpdateReceiver, makeGattUpdateIntentFilter());
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
    private void processTelemetryData() {
        /* https://wiki.lazerswarm.com/wiki/Recoil:Main_Page */
        final byte[] data = telemetryCharacteristic.getValue();
        if (data != null && data.length > 0) {
            int continuousCounter = (byte)(data[RECOIL_OFFSET_COMMAND_ID] & (byte)0x0F);
            int commandId = (byte)(data[RECOIL_OFFSET_COMMAND_ID] >> 4 & (byte)0x0F);
            if (commandId != trackedCommandId) {
                trackedCommandId = commandId;
                GodotLib.calldeferred(instanceId, "_changed_lazer_telem_commandId", new Object[]{trackedCommandId});
            }
            int playerId = data[RECOIL_OFFSET_PLAYER_ID];
            if (playerId != trackedPlayerId) {
                trackedPlayerId = playerId;
                GodotLib.calldeferred(instanceId, "_changed_lazer_telem_playerId", new Object[]{trackedPlayerId});
            }
            int buttonsPressed = data[RECOIL_OFFSET_BUTTONS_BITMASK];
            if (buttonsPressed != 0) {
                GodotLib.calldeferred(instanceId, "_changed_telem_button_pressed", new Object[]{buttonsPressed});
            }
            /* Rather than monitor if a button is currently pressed, we monitor the counter. Usually
               when the player presses a button, we see many packets showing that the button is
               pressed. We don't want to toggle recoil or modes with every packet we receive so it
               makes more sense to just monitor when the counter changes so we can toggle exactly
               once each time that button is pressed. */
            int triggerBtnCounter = (byte)(data[RECOIL_OFFSET_RELOAD_TRIGGER_COUNTER] & (byte)0x0F);
            if (triggerBtnCounter != trackedTriggerBtnCounter) {
                trackedTriggerBtnCounter = triggerBtnCounter;
                GodotLib.calldeferred(instanceId, "_changed_lazer_telem_triggerBtnCounter", new Object[]{trackedTriggerBtnCounter});
            }
            /* NOTE: Below is a conversion performed on the nibble (last/low 4-bits) to make it act
            * as a proper 4-bit int which counts 0-15. */
            int reloadBtnCounter = (byte)(data[RECOIL_OFFSET_RELOAD_TRIGGER_COUNTER] >> 4 & (byte)0x0F);
            if (reloadBtnCounter != trackedReloadBtnCounter) {
                trackedReloadBtnCounter = reloadBtnCounter;
                GodotLib.calldeferred(instanceId, "_changed_lazer_telem_reloadBtnCounter", new Object[]{trackedReloadBtnCounter});
            }
            int thumbBtnCounter = data[RECOIL_OFFSET_THUMB_COUNTER];
            if (thumbBtnCounter != trackedThumbBtnCounter) {
                trackedThumbBtnCounter = thumbBtnCounter;
                GodotLib.calldeferred(instanceId, "_changed_lazer_telem_thumbBtnCounter", new Object[]{trackedThumbBtnCounter});
            }
            int powerBtnCounter = data[RECOIL_OFFSET_POWER_COUNTER];
            if (powerBtnCounter != trackedPowerBtnCounter) {
                trackedPowerBtnCounter = powerBtnCounter;
                GodotLib.calldeferred(instanceId, "_changed_lazer_telem_powerBtnCounter", new Object[]{trackedPowerBtnCounter});
            }
            /* We send the battery telemetry every time, so we can track the battery average
               and we use it to track if we are still connected to the gun. */
            int batteryLvl = data[RECOIL_OFFSET_BATTERY_LEVEL];
            trackedBatteryLvl = batteryLvl;
            GodotLib.calldeferred(instanceId, "_lazer_telem_batteryLvl", new Object[]{trackedBatteryLvl});
            /* bytes are always signed in Java and if you don't do "& 0xFF" here, you will get
               negative numbers in the hitById# field when using player IDs > 32 */
            /* shotById1 defaults to 0 and a shot counter of 0. So using a player ID of 0 would
               result in missing every 8th shot even with complex logic.
               shotById1 is only the left most or most significant 6 bytes. So a max of 0-63.
               So 62 players max, because we do not use 0 since it is default for no shot.*/
            int shotById1 = (data[RECOIL_OFFSET_HIT_BY1] & 0xFF) >> 2;
            int shotById2 = (data[RECOIL_OFFSET_HIT_BY2] & 0xFF) >> 2;
            /* The first 2 most significant bits of RECOIL_OFFSET_HIT_BY1 are the
                least 2 significant bits of the weapon profile ID*/
            int wpnProfileLeast = data[RECOIL_OFFSET_HIT_BY1] & 0xFF000000;
            /* The 2 least significant bits of RECOIL_OFFSET_HIT_BY2 are the 2 most
               significant bits of the weapon profile ID being used (combine with
               2 most significant bits from byte 8 which is RECOIL_OFFSET_HIT_BY1_SHOTID )*/
            int wpnProfileMost = data[RECOIL_OFFSET_HIT_BY2] & 0x000000FF;
            /* Commented out until we are ready to implement it.
            logger("*** wpnProfileLeast = " + wpnProfileLeast + "  | wpnProfileMost = "
                + wpnProfileMost, 1);
            */
            /* Trying to extract the charge level. It is the middle 3 bits.*/
            int chargeLevel =data[RECOIL_OFFSET_HIT_BY1_SHOTID] & 0x00FFF000;
            int chargeLevel2 = chargeLevel >> 3;
            int chargeLevel3 = chargeLevel << 2;
            /* Commented out until we are ready to implement it.
            logger("chargeLevel = " + chargeLevel + "  | chargeLevel2 = " +
                chargeLevel2 + "  | chargeLevel3 = " + chargeLevel3, 1);
            */
            // Only the right-most or least significant 3 bits make up the shot Counter, octal.
            int shotCounter1 = (byte) (data[RECOIL_OFFSET_HIT_BY1_SHOTID] & 0x07);
            int shotCounter2 = (byte) (data[RECOIL_OFFSET_HIT_BY2_SHOTID] & 0x07);
            int sensorsHit = data[RECOIL_OFFSET_SENSORS_HIT_BITMASK];
            if (shotById1 != 0) {
                /* We can not use a PlayerId of 0 because it is the default for shotById1 and shotById2.
                It is impossible to distinguish a real shot by this player from regular telemetry data
                any time that shotCounter rolls back to 0.
                shotById2 is only non-zero if the gun recieves 2 shots at the same time and thus
                shotById1 will also have to be non-zero. */
                GodotLib.calldeferred(instanceId, "_changed_lazer_telem_shot_data", new Object[]{shotById1, shotCounter1, shotById2, shotCounter2});
                logger("sesorsHit = " + sensorsHit, 1);
            }
            int shotsRemaining = data[RECOIL_OFFSET_SHOTS_REMAINING] & 0xFF;
            if (shotsRemaining != trackedShotsRemaining) {
                trackedShotsRemaining = shotsRemaining;
                GodotLib.calldeferred(instanceId, "_changed_lazer_telem_shotsRemaining", new Object[]{trackedShotsRemaining});
            }
            int status = data[RECOIL_OFFSET_STATUS];
            int playerIdAccepted = data[RECOIL_OFFSET_PLAYER_ID_ACCEPT];
            /* Just to be clear the Weapon Profile below is the guns current profile.
               Where as the above Weapon Profiles are the one for the shooter that
               has shot you. */
            int wpnProfileAgain = data[RECOIL_OFFSET_WEAPON_PROFILE];
            /* Commented out until we are ready to implement it.
            logger("status = " + status + "  | playerIdAccepted = " +
                playerIdAccepted + "  | wpnProfileAgain = " +
                wpnProfileAgain, 1);
            */
            // TODO: Grenade Pairing.
        }
    }

    private static IntentFilter makeGattUpdateIntentFilter() {
        final IntentFilter intentFilter = new IntentFilter();
        intentFilter.addAction(BluetoothLeService.ACTION_GATT_CONNECTED);
        intentFilter.addAction(BluetoothLeService.ACTION_GATT_DISCONNECTED);
        intentFilter.addAction(BluetoothLeService.ACTION_GATT_SERVICES_DISCOVERED);
        intentFilter.addAction(BluetoothLeService.TELEMETRY_DATA_AVAILABLE);
        intentFilter.addAction(BluetoothLeService.ID_DATA_AVAILABLE);
        intentFilter.addAction(BluetoothLeService.CHARACTERISTIC_WRITE_FINISHED);
        return intentFilter;
    }

    /* Android callbacks. */
    private ScanCallback anyLeScanCallbacks = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, ScanResult result) {
            super.onScanResult(callbackType, result);
            checkDeviceName(result.getDevice());
        }

        @Override
        public void onBatchScanResults(List<ScanResult> results) {
            super.onBatchScanResults(results);
            for (ScanResult result : results) {
                if (checkDeviceName(result.getDevice()))
                    return;
            }
        }

        @Override
        public void onScanFailed(int errorCode) {
            super.onScanFailed(errorCode);
            logger("Bluetooth Scan Failed with error code: " + Integer.toString(errorCode), 3);
        }

        private boolean checkDeviceName(BluetoothDevice device) {
            if (device.getName() != null && !device.getName().isEmpty()) {
                if ((btDeviceAddress.isEmpty() && device.getName().startsWith("SRG1")) || btDeviceAddress.equals(device.getAddress())) {
                    logger("Connecting to " + device.getName() + " '" + device.getAddress() + "'", 1);
                    //TODO: Godot Callback set status to connecting to gun.
                    bluetoothScanner.stopScan(anyLeScanCallbacks);
                    bluetoothScanning = false;
                    btDeviceAddress = device.getAddress();
                    setupBLEServiceConnection();
                    return true;
                }
            }
            return false;
        }
    };

    // Handles various events fired by the BLE Service.
    private final BroadcastReceiver mGattUpdateReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();
            if (BluetoothLeService.ACTION_GATT_CONNECTED.equals(action)) {
                GodotLib.calldeferred(instanceId, "_on_lazer_gun_connected", new Object[]{});
            }
            else if (BluetoothLeService.ACTION_GATT_DISCONNECTED.equals(action)) {
                //GodotLib.calldeferred(instanceId, "_on_lazer_gun_disconnected", new Object[]{});
                //This is called too often to be reliable even when the device is still connected.
            }
            else if (BluetoothLeService.ACTION_GATT_SERVICES_DISCOVERED.equals(action)) {
                // Show all the supported services and characteristics on the user interface.
                //displayGattServices(mBluetoothLeService.getSupportedGattServices());
                //logger("Services discovered!", 1);
                //GodotLib.calldeferred(instanceId, "_on_lazer_gun_connected", new Object[]{});
                for (BluetoothGattService gattService : bluetoothService.getSupportedGattServices()) {
                    logger("Service: " + gattService.getUuid().toString(), 1);
                    if (gattService.getUuid().toString().equals(GattAttributes.RECOIL_MAIN_SERVICE)) {
                        logger("Found Recoil Main Service", 1);
                        telemetryCharacteristic = gattService.getCharacteristic(UUID.fromString(GattAttributes.RECOIL_TELEMETRY_UUID));
                        if (telemetryCharacteristic != null) {
                            bluetoothService.setCharacteristicNotification(telemetryCharacteristic, true);
                            logger("Found Telemetry characteristic.", 1);
                        }
                        else {
                            logger("Failed to find Telemetry characteristic!", 3);
                            return;
                        }
                        commandCharacteristic = gattService.getCharacteristic(UUID.fromString(GattAttributes.RECOIL_COMMAND_UUID));
                        configCharacteristic = gattService.getCharacteristic(UUID.fromString(GattAttributes.RECOIL_CONFIG_UUID));
                        BluetoothGattCharacteristic idCharacteristic = gattService.getCharacteristic(UUID.fromString(GattAttributes.RECOIL_ID_UUID));
                        if (idCharacteristic != null) {
                            bluetoothService.readCharacteristic(idCharacteristic); // to get the blaster type, rifle or pistol
                            logger("Found ID characteristic.", 1);
                        }
                        else {
                            logger("Failed to find ID characteristic!", 3);
                        }
                    }
                }
            }
            else if (bluetoothService.TELEMETRY_DATA_AVAILABLE.equals(action)) {
                processTelemetryData();
            }
            else if (bluetoothService.ID_DATA_AVAILABLE.equals(action)) {
                lazerType = intent.getByteExtra(BluetoothLeService.EXTRA_DATA, BLASTER_TYPE_PISTOL);
                if (lazerType == BLASTER_TYPE_RIFLE) {
                    logger("Riffle detected.", 1);
                }
                else {
                    // We'll automatically assume that this is a pistol
                    logger("Pistol detected.", 1);
                }
            }
            else if (bluetoothService.CHARACTERISTIC_WRITE_FINISHED.equals(action)) {
                //TODO: Start Reloading using a timer call to godot for timer.
            }
        }
    };

    /* Godot callbacks you can reimplement, as SDKs often need them */

    protected void onMainActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == 1) {
            GodotLib.calldeferred(instanceId, "_on_activity_result_bt_enable", new Object[]{});
        }
    }

    protected void onMainRequestPermissionsResult(int requestCode, String permissions[], int[] grantResults) {
        boolean granted = grantResults.length > 0 && grantResults[0] == PackageManager.PERMISSION_GRANTED;
        //GodotLib.calldeferred(mInstanceId, "_on_request_premission_result", new Object[]{requestCode, permissions[0], granted});
        if (requestCode == 2) {
            GodotLib.calldeferred(instanceId, "_on_activity_result_fine_access", new Object[]{});
        }
        logger("Permission: "+ requestCode + " | " + permissions[0] + " allowed? " + granted, 1);
    }

    protected void onMainPause() {}
    protected void onMainResume() {}
    protected void onMainDestroy() {}

    protected void onGLDrawFrame(GL10 gl) {}
    protected void onGLSurfaceChanged(GL10 gl, int width, int height) {} // singletons will always miss first onGLSurfaceChanged call

    /* **********************************************************************
     * Definitions
     * ********************************************************************** */

    /**
     * Initilization of the Singleton called by Godot
     */

    static public Godot.SingletonBase initialize(Activity p_activity) {
        return new FreecoiL(p_activity);
    }

    /**
     * Constructor
     */

    public FreecoiL(Activity p_activity) {
        registerClass("FreecoiL", new String[]
                {
                        "init",
                        "bluetoothStatus",
                        "enableBluetooth",
                        "fineAccessPermissionStatus",
                        "enableFineAccess",
                        "startBluetoothScan",
                        "stopBluetoothScan",
                        "vibrate",
                        "setLazerId",
                        "startReload",
                        "finishReload",
                        "setShotMode",
                        "enableRecoil"
                });

        this.appActivity = p_activity;
        this.appContext = appActivity.getApplicationContext();
        this.appInstance = this;
    }
}

