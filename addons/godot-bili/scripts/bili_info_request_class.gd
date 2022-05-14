# bili信息的http api 请求
extends HTTPRequest
class_name BiliInfoRequest

signal info_completed(info_dict, type)

# 不能请求太快，太快B站服务器会不响应
# 我测试最快是1秒一个，也不要多发并行， 也不建议间隔改到比1小
export(float) var request_gap_time = 1.0

var _timer = Timer.new()
var _request_type_arr := []
var _keys_arr := []
var _pararms_arr := []

onready var bili_utils = get_node("/root/BiliUtils")


func _ready():
	_timer.one_shot = true
	_timer.wait_time = request_gap_time
	add_child(_timer)
	_timer.connect("timeout", self, "_on_timer_timeout")
	# 默认开启 多线程
	use_threads = true
	connect("request_completed", self, "_on_http_request_completed")

# 不应该直接调用，应该使用add_to_arr添加到队列里
func request_info(keys: PoolStringArray, params: Dictionary):
	var info_api = bili_utils.get_api_dict(keys)
	var method = bili_utils.get_method_by_api(info_api)
	# 等待前一个request完成, 其实应该不需要
	while get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		yield(get_tree(), "idle_frame")
	var error = request(bili_utils.url_add_params(info_api, params), [], true, method)
	if error != OK:
		push_error("HTTP 请求发生了错误。")


func request_user_info(uid: int):
	var request_type = "user_info"
	var keys := ["user", "info", "info"]
	var params := {"mid": uid}
	add_to_arr(keys, params, request_type)


func request_room_info(room_id: int):
	var request_type = "room_info"
	var keys := ["live", "info", "room_play_info_v2"]
	var params := {"room_id": room_id}
	add_to_arr(keys, params, request_type)


func request_chat_conf(room_real_id: int):
	var request_type = "chat_conf"
	var keys := ["live", "info", "chat_conf"]
	var params := {"room_id": room_real_id}
	add_to_arr(keys, params, request_type)


func add_to_arr(keys, params, request_type):
	_keys_arr.append(keys)
	_pararms_arr.append(params)
	_request_type_arr.append(request_type)
	if (
		_keys_arr.size() > 0
		and _timer.is_stopped()
	):
		_timer.start()
		if get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			keys = _keys_arr.pop_front()
			params = _pararms_arr.pop_front()
			request_info(keys, params)


func _on_timer_timeout():
	if _keys_arr.size() > 0:
		_timer.start()
		if get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
			var keys = _keys_arr.pop_front()
			var params = _pararms_arr.pop_front()
			request_info(keys, params)


func _on_http_request_completed(
	result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray
):
	var dict = JSON.parse(body.get_string_from_utf8()).result
	emit_signal("info_completed", dict["data"], _request_type_arr.pop_front())
