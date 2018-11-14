extends ColorRect

onready var FullAuto = get_node("Label2/FullAuto")
onready var SemiAuto = get_node("Label3/SemiAuto")
onready var Burst3 = get_node("Label4/Burst3")

# Called when the node enters the scene tree for the first time.
func _ready():
    FullAuto.pressed = SettingsConf.S.QuickStart.full_auto_allowed
    SemiAuto.pressed = SettingsConf.S.QuickStart.semi_auto_allowed
    Burst3.pressed = SettingsConf.S.QuickStart.burst_3_allowed
    validate_modes()
    

func validate_modes():
    var at_least_one = false
    if FullAuto.pressed:
        at_least_one = true
    elif SemiAuto.pressed:
        at_least_one = true
    elif Burst3.pressed:
        at_least_one == true
    if not at_least_one:
        SemiAuto.pressed = true
        SettingsConf.S.QuickStart.semi_auto_allowed = true
        


func _on_Burst3_pressed():
    SettingsConf.S.QuickStart.burst_3_allowed = Burst3.pressed
    validate_modes()


func _on_SemiAuto_pressed():
    SettingsConf.S.QuickStart.semi_auto_allowed = SemiAuto.pressed
    validate_modes()


func _on_FullAuto_pressed():
    SettingsConf.S.QuickStart.full_auto_allowed = FullAuto.pressed
    validate_modes()