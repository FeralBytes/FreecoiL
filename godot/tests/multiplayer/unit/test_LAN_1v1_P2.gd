extends "res://addons/gut/test.gd"

var Obj
var _obj
var _map_maker

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

func test_udp_broadcast_rxd_from_server():
    _obj.search_for_peers()
    yield(yield_for(1.0), YIELD)
    assert_ne(_obj.udp_test_from_peer, _obj.host_udp_broadcast_uid)
    assert_ne(_obj.udp_test_from_peer, 0)
    
func test_udp_broadcast_invite_rxd_from_server_host():
    yield(yield_for(0.5), YIELD)
    assert_eq(Settings.Session.get_data("server_invite"), true)
    
func test_join_server_lobby():
    var wait_twice = 0
    _obj.setup_as_client()
    var mups_status = Settings.Network.get_data("mups_status")
    while mups_status.hash() == {"1": "connected"}.hash():
        yield(yield_for(0.5), YIELD)
        mups_status = Settings.Network.get_data("mups_status")
        wait_twice += 1
        if wait_twice >= 2:
            break
    assert_ne(mups_status.hash(), {"1": "connected"}.hash())
    
func test_client_rx_server_ready():
    var waited = 0
    var mups_ready = Settings.Network.get_data("mups_ready")
    mups_ready[Settings.Session.get_data("mup_id")] = true
    Settings.Network.set_data("mups_ready", mups_ready)
    while _obj.test_all_mups_were_ready == false:
        yield(get_tree(), 'idle_frame')
        waited += 1
        if waited >= 10:
            break
    assert_eq(_obj.test_all_mups_were_ready, true)

func test_teardown_network():
    yield(_obj.reset_networking(), "completed")
    assert_eq(get_tree().get_network_peer(), null)
   
func test_connect_setup_as_a_server():
    _obj.setup_server_part1()
    yield(yield_for(0.1), YIELD)
    assert_has(_obj.network_loops, "_hosting_send_udp_broadcast")
    var wait_twice = 0
    var mups_status = Settings.Network.get_data("mups_status")
    while mups_status.hash() == {"1": "connected"}.hash():
        yield(yield_for(0.5), YIELD)
        mups_status = Settings.Network.get_data("mups_status")
        wait_twice += 1
        if wait_twice >= 2:
            break
    assert_ne(mups_status.hash(), {"1": "connected"}.hash())

func test_client_can_connect():
    pending()

