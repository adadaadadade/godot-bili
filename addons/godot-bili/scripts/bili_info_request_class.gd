extends HTTPRequest
class_name BiliInfoRequest

signal info_completed(info_dict, type)

var _request_type = 0

onready var bili_utils = get_node("/root/BiliUtils")

func _ready():
	# 默认开启 多线程
	use_threads = true
	connect("request_completed", self, "_on_http_request_completed")


func request_info(keys: PoolStringArray, params: Dictionary):
	# 等待前一个request完成
	while get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		yield(get_tree(), "idle_frame")

	var info_api = bili_utils.get_api_dict(keys)
	var method = bili_utils.get_method_by_api(info_api)
	var error = request(bili_utils.url_add_params(info_api, params), [], true, method)
	if error != OK:
		push_error("HTTP 请求发生了错误。")


func request_user_info(uid: int):
	_request_type = "user_info"
	var keys := ["user", "info", "info"]
	var params := {"mid": uid}
	request_info(keys, params)


func request_room_info(room_id: int):
	_request_type = "room_info"
	var keys := ["live", "info", "room_play_info_v2"]
	var params := {"room_id": room_id}
	request_info(keys, params)


func request_chat_conf(room_real_id: int):
	_request_type = "chat_conf"
	var keys := ["live", "info", "chat_conf"]
	var params := {"room_id": room_real_id}
	request_info(keys, params)


func _on_http_request_completed(
	result: int, response_code: int, headers: PoolStringArray, body: PoolByteArray
):
	var dict = JSON.parse(body.get_string_from_utf8()).result
	emit_signal("info_completed", dict["data"], _request_type)
