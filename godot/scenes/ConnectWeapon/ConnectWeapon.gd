extends TextureButton

var blink_timer = Timer.new()
var green = 0
var blue = 0
var increasing = true
var countdown
var scene = null
var state = "disconnected"
var pistol_clear = preload("res://assets/images/pistol.png")
var pistol_blur = preload("res://assets/images/pistol_blur.png")

onready var ConnectionCompleteSnd = get_node("ConnectionCompleteSnd")
onready var Countdown = get_node("Countdown")
onready var ConnectPopup = get_node("ConnectPopup")
# This Popup is a real popup because there does not seem to be an easy way to 
# make a top tree node show on top of all of the rest.
onready var ConnectWeapon2 = get_node("ConnectPopup/ConnectWeapon2")
# Called when the node enters the scene tree for the first time.
func _ready():
    add_to_group("FreecoiL")
    add_to_group("connect_weapon")
    blink_timer.connect("timeout", self, "_on_adjust_blink")
    blink_timer.wait_time = 0.02
    add_child(blink_timer)
    if FreecoiLInterface.laser_is_connected:
        self.disabled = true
        self.texture_normal = pistol_clear
        self.state = "connected"
    else:
        fi_laser_gun_disconnected()
        

#func fi_trigger_btn_pushed():
#    empty_gun_shot.play()
    
func fi_laser_gun_connected():
    self.disabled = true
    self.texture_normal = pistol_clear
    Countdown.stop()
    blink_timer.stop()
    set_modulate(Color(1,1,1))
    ConnectionCompleteSnd.play()
    
func fi_laser_gun_disconnected():
    Countdown.stop()
    blink_timer.start()
    self.disabled = false
    self.texture_normal = pistol_blur
    self.state = "disconnected"
    
func fi_bt_connect_timeout():
    fi_laser_gun_disconnected()
    
func fi_bt_connection_timed_out():
    fi_laser_gun_disconnected()

func _on_ConnectWeapon_pressed():
    self.disabled = true
    countdown = 10
    Countdown.start()
    self.state = "connecting"
    self.texture_normal = pistol_clear
    FreecoiLInterface.connect_to_laser_gun()

func _on_ConnectWeapon2_pressed():
    ConnectWeapon2.disabled = true
    countdown = 10
    Countdown.start()
    self.state = "connecting"
    self.texture_normal = pistol_clear
    ConnectWeapon2.text = "Connecting..." + "%02d" % countdown
    set_modulate(Color(1,1,1))
    FreecoiLInterface.connect_to_laser_gun()
    
func _on_adjust_blink():
    if green <= 0:
        increasing = true
    if green >= 1:
        increasing = false
    if increasing:
        if self.state == "connecting":
            self.texture_normal = pistol_blur
            green += 0.02
        else:
            green += 0.02
            blue += 0.02
    else:
        if self.state == "connecting":
            self.texture_normal = pistol_clear
            green -= 0.02
        else:
            green -= 0.02
            blue -= 0.02
    set_modulate(Color(1, green, blue))


func _on_Countdown_timeout():
    countdown -= 1
    if countdown < 1:
        ConnectWeapon2.disabled = false
        self.texture_normal = pistol_blur
        ConnectWeapon2.text = "Connect To Weapon"
    else:
        ConnectWeapon2.text = "Connecting... " + "%02d" % countdown
        Countdown.start()
    
#############################
# connect_weapon group funcs
###############################
func connect_weapon_guard(s):
    pass
    print("SetConf.Saved.SetConf.test = ", Settings.Testing.get_data("SetConf.test"))
    if Settings.Testing.get_data("SetConf.test") == null:
        get_tree().call_group("Container", "goto_scene", s)
    else:
        scene = s
        ConnectPopup.popup_centered()
