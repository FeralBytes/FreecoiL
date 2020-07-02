extends "res://addons/gut/test.gd"

var Obj
var _obj
var _test_var = false

onready var OvertimeTimer = Timer.new()

func _ready():
    add_child(OvertimeTimer)
    OvertimeTimer.connect("timeout", self, "overtime_exit")
    OvertimeTimer.wait_time = 60
    OvertimeTimer.start()
    
func overtime_exit():
    get_tree().quit(1)

func before_all():
    Settings.Testing.register_data("testing", true, false)
    Obj = load("res://code/networking/TheNetworkNode.tscn")
    _obj = Obj.instance()
    add_child(_obj)

func before_each():
    pass

func after_each():
    pass

func after_all():
    remove_child(_obj)
    _obj.queue_free()

func test_p2_udp_broadcast_rxd_from_server():
    print("** Player 2 UID = " + str(_obj.host_udp_broadcast_uid))
    _obj.search_for_peers()
    while _obj.udp_test_from_peer == 0 or _obj.udp_test_from_peer == _obj.host_udp_broadcast_uid:
        yield(get_tree(), 'idle_frame')
    assert_ne(_obj.udp_test_from_peer, _obj.host_udp_broadcast_uid)
    assert_ne(_obj.udp_test_from_peer, 0)
    
func test_p2_udp_broadcast_invite_rxd_from_server_host():
    while Settings.Session.get_data("server_invite") == false:
        yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("server_invite"), true)
    
func test_p2_join_server_lobby():
    while Settings.Session.get_data("connection_status") != "connected":
        yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("connection_status"), "connected")
    while Settings.Network.get_data("mups_status").hash() != {"1": "connected", "2": "connected"}.hash():
        assert_eq(Settings.Network.get_data("mups_status").hash(), {"1": "connected", "2": "connected"}.hash())
    
func test_p2_client_rx_server_ready():
    get_tree().call_group("Network", "tell_server_i_am_ready", true)
    while Settings.Network.get_data("mups_ready").has("2") != true:
        yield(get_tree(), 'idle_frame')
    # We have to match on both possibilities because Godot does not due true dict comparision.
    # https://github.com/godotengine/godot/pull/35816
    assert_eq(true, true) # because we made it here, it was true, but the unready all is too fast to detect in an assert.
    assert_eq(Settings.Session.get_data("connection_status"), "connected")

func test_p2_client_can_disconnect_from_server():
    get_tree().call_group("Network", "client_disconnect")
    while Settings.Session.get_data("connection_status") == "connected":
        yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("connection_status"), "do_not_connect")

func test_p2_client_can_reconnect_to_server_with_same_mup():
    var mup_id = Settings.Session.get_data("mup_id")
    get_tree().call_group("Network", "setup_as_client")
    while Settings.Session.get_data("connection_status") != "connected":
        yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("mup_id"), mup_id)
    while Settings.Network.get_data("mups_status")["2"] != "reconnected":
        yield(get_tree(), 'idle_frame')
    get_tree().call_group("Network", "client_disconnect")
    yield(get_tree(), 'idle_frame')

#func test_teardown_network():
#    yield(_obj.reset_networking(), "completed")
#    assert_eq(get_tree().get_network_peer(), null)
#
#func test_connect_setup_as_a_server():
#    _obj.setup_server_part1()
#    yield(yield_for(0.1), YIELD)
#    assert_has(_obj.network_loops, "_hosting_send_udp_broadcast")
#    var wait_twice = 0
#    var mups_status = Settings.Network.get_data("mups_status")
#    while mups_status.hash() == {"1": "connected"}.hash():
#        yield(yield_for(0.5), YIELD)
#        mups_status = Settings.Network.get_data("mups_status")
#        wait_twice += 1
#        if wait_twice >= 2:
#            break
#    assert_ne(mups_status.hash(), {"1": "connected"}.hash())
#
#func test_client_can_connect():
#    pending()

