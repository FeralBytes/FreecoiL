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
    add_to_group("lazercoil")
    add_to_group("connect_weapon")
    blink_timer.connect("timeout", self, "_on_adjust_blink")
    blink_timer.wait_time = 0.02
    add_child(blink_timer)
    if LazerInterface.state_lazer_gun_is_connected:
        self.disabled = true
        self.texture_normal = pistol_clear
        self.state = "connected"
    else:
        li_lazer_gun_disconnected()
        
func delayed_goto_scene():
    #Trying to fix crash when going to game scene too soon after gun is connected.
    yield(get_tree().create_timer(0.5), "timeout" )
    var s = scene
    scene = null
    SceneManager.goto_scene(s)

#func li_trigger_btn_pushed():
#    empty_gun_shot.play()
    
func li_lazer_gun_connected():
    self.disabled = true
    self.texture_normal = pistol_clear
    Countdown.stop()
    blink_timer.stop()
    set_modulate(Color(1,1,1))
    if scene != null:
        call_deferred("delayed_goto_scene")
    else:
        ConnectionCompleteSnd.play()
    
func li_lazer_gun_disconnected():
    Countdown.stop()
    blink_timer.start()
    self.disabled = false
    self.texture_normal = pistol_blur
    self.state = "disconnected"
    
func li_bt_connect_timeout():
    li_lazer_gun_disconnected()
    
func li_bt_connection_timed_out():
    li_lazer_gun_disconnected()

func _on_ConnectWeapon_pressed():
    self.disabled = true
    countdown = 10
    Countdown.start()
    self.state = "connecting"
    self.texture_normal = pistol_clear
    LazerInterface.connect_to_lazer_gun()

func _on_ConnectWeapon2_pressed():
    ConnectWeapon2.disabled = true
    countdown = 10
    Countdown.start()
    self.state = "connecting"
    self.texture_normal = pistol_clear
    ConnectWeapon2.text = "Connecting..." + "%02d" % countdown
    LazerInterface.connect_to_lazer_gun()
    
func _on_adjust_blink():
    if green <= 0:
        increasing = true
    if green >= 1:
        increasing = false
    if increasing:
        green += 0.02
        blue += 0.02
        if self.state == "connecting":
            self.texture_normal = pistol_blur
    else:
        green -= 0.02
        blue -= 0.02
        if self.state == "connecting":
            self.texture_normal = pistol_clear
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
    print("SetConf.Saved.SetConf.test = ", SetConf.Saved.SetConf.test)
    if SetConf.Saved.SetConf.test:
        SceneManager.goto_scene(s)
    else:
        scene = s
        ConnectPopup.popup_centered()
