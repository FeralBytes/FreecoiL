extends "res://addons/gut/test.gd"

var Obj
var _obj
var _map_maker

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
    
func test_p1_udp_broadcast_rxd_from_client():
    print("** Player 1 UID = " + str(_obj.host_udp_broadcast_uid))
    _obj.search_for_peers()
    while _obj.udp_test_from_peer == 0 or _obj.udp_test_from_peer == _obj.host_udp_broadcast_uid:
        yield(get_tree(), 'idle_frame')
    assert_ne(_obj.udp_test_from_peer, _obj.host_udp_broadcast_uid)
    assert_ne(_obj.udp_test_from_peer, 0)

func test_p1_server_sends_udp_hosting_invite():
    _obj.setup_server_part1()
    yield(yield_for(0.1), YIELD)
    assert_does_not_have(_obj.network_loops, "_udp_broadcast_tx")
    assert_has(_obj.network_loops, "_hosting_send_udp_broadcast")

func test_p1_client_joins_the_server():
    var wait_twice = 0
    while Settings.Network.get_data("mups_status").hash() != {"1": "connected", "2": "connected"}.hash():
        yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Network.get_data("mups_status").hash(), {"1": "connected", "2": "connected"}.hash())
    
func test_p1_server_rx_client_ready():
    get_tree().call_group("Network", "tell_server_i_am_ready", true)
    yield(get_tree(), 'idle_frame')
    while Settings.Session.get_data("all_ready") == false:
        yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Session.get_data("all_ready"), true)
    assert_eq(Settings.Session.get_data("connection_status"), "connected")
    get_tree().call_group("Network", "unready_all_mups")
    while Settings.Network.get_data("mups_status")["2"] == "connected":
        yield(get_tree(), 'idle_frame')

func test_p1_client_can_reconnect_to_server():
    assert_eq(Settings.Network.get_data("mups_status")["2"], "disconnected")
    while Settings.Network.get_data("mups_status")["2"] == "disconnected":
        yield(get_tree(), 'idle_frame')
    assert_eq(Settings.Network.get_data("mups_status")["2"], "reconnected")
    
#func test_teardown_network():
#    yield(_obj.reset_networking(), "completed")
#    assert_eq(get_tree().get_network_peer(), null)
#
#func test_connect_as_a_client_to_server():
#    _obj.search_for_peers()
#    yield(yield_for(1.0), YIELD)
#    assert_ne(_obj.udp_test_from_peer, _obj.host_udp_broadcast_uid)
#    assert_ne(_obj.udp_test_from_peer, 0)
#    yield(yield_for(0.5), YIELD)
#    assert_eq(Settings.Session.get_data("server_invite"), true)
#    var wait_twice = 0
#    _obj.setup_as_client()
#    var mups_status = Settings.Network.get_data("mups_status")
#    while mups_status.hash() == {"1": "connected"}.hash():
#        yield(yield_for(0.5), YIELD)
#        mups_status = Settings.Network.get_data("mups_status")
#        wait_twice += 1
#        if wait_twice >= 2:
#            break
#    assert_ne(mups_status.hash(), {"1": "connected"}.hash())
     
    
