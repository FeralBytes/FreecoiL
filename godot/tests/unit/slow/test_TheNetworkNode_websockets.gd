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

func test_send_udp_broadcast():
    _obj.search_for_peers()
    yield(yield_for(0.2), YIELD)
    assert_eq(_obj.udp_test, ["Want to play " + Settings.GAME_NAME + "?", "", null, _obj.host_udp_broadcast_uid])
    _obj.stop_udp_peer_search()

func test_udp_broadcast_search_happens_2_times():
    _obj.udp_test_broadcast_rx_count = 0
    _obj.udp_test_broadcast_tx_count = 0
    _obj.search_for_peers()
    yield(yield_for(1), YIELD)
    _obj.stop_udp_peer_search()
    assert_eq(_obj.udp_test_broadcast_tx_count, 2)
    assert_eq(_obj.udp_test_broadcast_rx_count, 2)
    
func test_websockets_can_connect():
    _obj.init_websocket_server()
    _obj.init_websocket_client()
    _obj.websocket_client_connect_to_url("ws://127.0.0.1:58888", null)
    yield(yield_for(0.1), YIELD)
    assert_eq(_obj.websockets_test_server_connected, true)
    assert_eq(_obj.websockets_test_client_connected, true)

#func test_websockets_can_rx_data():
#    _obj.websocket_client_send_data("Test Server".to_utf8())
#    yield(yield_for(0.1), YIELD)
#    if typeof(_obj.websockets_test_server_rx_data) == TYPE_BOOL:  # Fail
#        assert_eq(true, false)
#    else:
#        assert_eq(_obj.websockets_test_server_rx_data.get_string_from_utf8(), "Test Server")
#    _obj.websocket_server_send_data(_obj.websockets_test_server_client_id, "Test Client".to_utf8())
#    yield(yield_for(0.5), YIELD)
#    if typeof(_obj.websockets_test_client_rx_data) == TYPE_BOOL:  # Fail
#        assert_eq(true, false)
#    else:
#        assert_eq(_obj.websockets_test_client_rx_data.get_string_from_utf8(), "Test Client")

func test_websocket_disconnect():
    _obj.websocket_client_disconnect()
    yield(yield_for(0.1), YIELD)
    assert_eq(_obj.websockets_test_client_requested_closed, true)
    assert_eq(_obj.websockets_test_server_disconnected, true)
    assert_eq(_obj.websockets_test_client_disconnected, true)

func test_websocket_reconnect():
    _obj.websockets_test_server_connected = false
    _obj.websockets_test_client_connected = false
    _obj.websockets_test_client_requested_closed = false
    _obj.websockets_test_server_disconnected = false
    _obj.websockets_test_client_disconnected = false
    _obj.websocket_client_connect_to_url("ws://127.0.0.1:58888", null)
    yield(yield_for(0.1), YIELD)
    assert_eq(_obj.websockets_test_server_connected, true)
    assert_eq(_obj.websockets_test_client_connected, true)
    _obj.websocket_client_disconnect()
    yield(yield_for(0.1), YIELD)
    assert_eq(_obj.websockets_test_client_requested_closed, true)
    assert_eq(_obj.websockets_test_server_disconnected, true)
    assert_eq(_obj.websockets_test_client_disconnected, true)

#func test_websockets_can_send_and_rx_echo():
#    _obj.websockets_test_client_connected = false
#    _obj.websocket_client_connect_to_url("wss://echo.websocket.org", null)
#    yield(yield_for(4), YIELD)
#    assert_eq(_obj.websockets_test_client_connected, true)
#    print("Host = ", _obj.websocket_client. get_connected_host())
#    #_obj.websocket_client_connect_to_url("ws://demos.kaazing.com/echo")  # ws://echo.websocket.org
#    _obj.websocket_client_send_data("Test Echo".to_utf8())
#    yield(yield_for(4), YIELD)
#    assert_eq(_obj.websockets_test_client_rx_data.get_string_from_utf8(), "Test Echo")


