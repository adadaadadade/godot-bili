# 主要节点，连接B站直播服务器
# B站直播间号非websocket连接的id， 1000之前的id会重定向到1000之后，本来1000之后的应该没影响
extends Node
class_name BiliLive

### 信号
# 连接成功
signal connect_success
# 收到包 _unpack 解包之后的 pack 为字典类型, 包含 data datapack_type protocol_version 字段
# 有些包 data 段非字典或格式不一，例如 连接认证的返回包默认返回{"code':0}和 心跳认证的返回包为此时房间人气 的int
# 可以考虑再加一个人气的信号，但其实也没必要，data段里的包里面有人气改变的类型
signal pack_received(pack)
# 为 pack 中的 data 段， 去掉 datapack_type protocol_version
# 为收到信息处理之后的包  data 为字典类型
signal data_received(data)

# 解压最大大小 30000大概就可以吧。。，反正大点也无所谓
const MAX_DECOMPRESS_SIZE = 50000
### 连接相关常量
const PROTOCOL_VERSION_RAW_JSON = 0
const PROTOCOL_VERSION_HEARTBEAT = 1
const PROTOCOL_VERSION_ZLIB_JSON = 2
const PROTOCOL_VERSION_BROTLI = 3

const DATAPACK_TYPE_HEARTBEAT = 2
const DATAPACK_TYPE_HEARTBEAT_RESPONSE = 3
const DATAPACK_TYPE_NOTICE = 5
const DATAPACK_TYPE_VERIFY = 7
const DATAPACK_TYPE_VERIFY_SUCCESS_RESPONSE = 8

const WS_PACKAGE_HEADER_TOTAL_LENGTH = 16
const WS_PACKAGE_OFFSET = 0
const WS_HEADER_OFFSET = 4
const WS_VERSION_OFFSET = 6
const WS_OPERATION_OFFSET = 8
const WS_SEQUENCE_OFFSET = 12

const WS_HEADER_DEFAULT_VERSION = 1
const WS_HEADER_DEFAULT_OPERATION = 1
const WS_HEADER_DEFAULT_SEQUENCE = 1
const WS_AUTH_OK = 0
const WS_AUTH_TOKEN_ERROR = -101

# 连接的房间 id 短id长id都可以
export(int) var room_id = 22032712
# 是否使用 wss, 导出时可能得设置证书
export(bool) var use_wss = false
# 心跳包发送间隔，不需要修改
export(float) var heartbeat_time = 30
# 是否print
export(bool) var use_log = false


#var _danmu_info: Dictionary
var room_info: Dictionary
var _chat_conf: Dictionary
var _connected_status: int

var uid: int = -1
# 房间真实id
var room_real_id: int
var bili_info_request_script = preload("bili_info_request_class.gd")

var _ws_client := WebSocketClient.new()
var _bili_info_request = bili_info_request_script.new()
var _heartbeat_timer := Timer.new()


func _ready():
	_heartbeat_timer.wait_time = heartbeat_time
	_heartbeat_timer.connect("timeout", self, "_on_timer_timeout")
	add_child(_heartbeat_timer)

	add_child(_bili_info_request)
	# 这个请求只进行几次，不需要考虑时间间隔
	_bili_info_request.request_gap_time = 0

	_ws_client.connect("connection_closed", self, "_on_ws_connection_closed")
	_ws_client.connect("connection_error", self, "_on_ws_connection_error")
	_ws_client.connect("connection_established", self, "_on_ws_connection_established")
	_ws_client.connect("data_received", self, "_on_ws_data_received")
	_ws_client.connect("connection_succeeded", self, "_on_ws_connection_succeeded")
	connect_room(room_id, use_wss)


func _process(delta):
	_ws_client.poll()

# 连接房间的函数，room_id 真房间号或是短房间号都可以
func connect_room(room_id, use_wss = false, should_reconnect = true):
	if use_wss:
		_ws_client.verify_ssl = true

	self.room_id = room_id
	_bili_info_request.request_room_info(room_id)
	room_info = yield(_bili_info_request, "info_completed")[0]
	room_real_id = room_info["room_id"]

	_bili_info_request.request_chat_conf(room_real_id)
	_chat_conf = yield(_bili_info_request, "info_completed")[0]

	var host_server_list: Array = _chat_conf["host_server_list"]
	host_server_list.invert()

	for host_dict in host_server_list:
		var host: String = host_dict["host"]
		var port: int = host_dict["port"]
		var ws_port: int = host_dict["ws_port"]
		var wss_port: int = host_dict["wss_port"]

		var use_port = wss_port if use_wss else ws_port
		var protocol = "wss" if use_wss else "ws"
		var uri = "{0}://{1}:{2}/sub".format([protocol, host, use_port])
		var err = _ws_client.connect_to_url(uri)

		self._connected_status = 1
		yield(_ws_client, "connection_error")
		self._connected_status = -1

		if self._connected_status >= 0:
			return
		if not should_reconnect:
			return
	if self._connected_status == -1:
		push_error("所有主机连接失败，程序终止")


func _send_heartbeat():
	if use_log:
		print("_send_heartbeat")
	self._send("", PROTOCOL_VERSION_HEARTBEAT, DATAPACK_TYPE_HEARTBEAT)


func _send(data, protocol_version, datapack_type):
	var pack_data = self._pack(data, protocol_version, datapack_type)
	self._ws_client.get_peer(1).put_packet(pack_data)


func _pack(data: String, protocol_version: int, datapack_type: int):
	var data_byte := data.to_utf8()
	var head_data := PoolByteArray()

	var pack_length = WS_PACKAGE_HEADER_TOTAL_LENGTH + data_byte.size()

	head_data.append_array(int2byte(pack_length))
	head_data.append_array(int2byte(WS_PACKAGE_HEADER_TOTAL_LENGTH, 2))
	head_data.append_array(int2byte(protocol_version, 2))
	head_data.append_array(int2byte(datapack_type))
	head_data.append_array(int2byte(1))

	var send_data = PoolByteArray()
	send_data.append_array(head_data)
	send_data.append_array(data_byte)
	return send_data


func _unpack(pack: PoolByteArray) -> Array:
	var ret := []
	var dict := {}

	var head := pack.subarray(0, 15)
	var data := pack.subarray(16, -1)
	var protocol_version_pack := head.subarray(6, 7)
	var datapack_type_pack := head.subarray(8, 11)
	var protocol_version := byte2int(protocol_version_pack)
	var datapack_type := byte2int(datapack_type_pack)
	if byte2int(pack.subarray(0, 3)) != pack.size():
		print("not equal")

	dict["protocol_version"] = protocol_version
	dict["datapack_type"] = datapack_type
	# 如果是压缩包，则解压后返回包内内容
	if protocol_version == PROTOCOL_VERSION_ZLIB_JSON:
		var decompress_data = data.decompress_dynamic(MAX_DECOMPRESS_SIZE, File.COMPRESSION_DEFLATE)
		var tail = decompress_data
		# 因为解开压缩之后包里面有很多个包是连在一块的，需要按照pack_length分开
		var pack_length = byte2int(tail.subarray(0, 3))
		while pack_length != tail.size():
			# 这里递归调用_unpack,可能再写一个函数分两层好点
			ret.append_array(_unpack(tail.subarray(0, pack_length - 1)))
			tail = tail.subarray(pack_length, -1)
			pack_length = byte2int(tail.subarray(0, 3))
		ret.append_array(_unpack(tail))
	# 心跳包的回应特殊，为人气的int
	elif datapack_type == DATAPACK_TYPE_HEARTBEAT_RESPONSE:
		dict["data"] = byte2int(data)
	# github 上的 b站API仓库说有这种压缩格式，但我没收到过，故不管
	elif protocol_version == PROTOCOL_VERSION_BROTLI:
		print("PROTOCOL_VERSION_BROTLI")
	else:
		var data_string = data.get_string_from_utf8()
		#print(data_string)
		if validate_json(data_string) != "":
			push_error("not validate_json")
		dict["data"] = JSON.parse(data_string).result
		ret.append(dict)

	return ret


static func byte2int(array: PoolByteArray) -> int:
	var ret := 0
	for byte in array:
		ret *= 256
		ret += byte
	return ret


# length 为字节数
static func int2byte(val: int, length: int = 4, big_endian = true) -> PoolByteArray:
	var ret = PoolByteArray()
	ret.resize(length)
	for i in range(0, length):
		var offset = length - i - 1 if big_endian else i
		ret.set(i, val >> (offset * 8))
	return ret


func _on_ws_connection_succeeded():
	if use_log:
		print("_on_ws_connection_succeeded")
	pass


# 当与服务器的连接被关闭时触发。was_clean_close 将是true 如果连接完全关闭。
func _on_ws_connection_closed(was_clean_close: bool):
	if use_log:
		print("_on_ws_connection_closed")
	pass


# 当与服务器的连接失败时触发。
func _on_ws_connection_error():
	if use_log:
		print("_on_ws_connection_error")
	pass


# 当与服务器建立连接时触发，protocol协议将包含与服务器达成一致的子协议。
func _on_ws_connection_established(protocol: String):
	if use_log:
		print("_on_ws_connection_established")
	var verify_data = {
		"uid": 0,
		"roomid": room_real_id,
		"protover": 1,
		"platform": "web",
		"clientver": "1.7.10",
		"type": 2,
		"key": self._chat_conf["token"]
	}
	print(verify_data)
	var data = to_json(verify_data)
	_send(data, PROTOCOL_VERSION_HEARTBEAT, DATAPACK_TYPE_VERIFY)

	_heartbeat_timer.start()


# 当收到 WebSocket 消息时触发。
func _on_ws_data_received():
	if use_log:
		print("_on_ws_data_received")
	while _ws_client.get_peer(1).get_available_packet_count() != 0:
		var pack = _ws_client.get_peer(1).get_packet()
		var pack_length := byte2int(pack.subarray(0, 3))
		var unpacks = _unpack(pack)
		for unpack in unpacks:
			emit_signal("pack_received", unpack)

			if unpack["datapack_type"] == DATAPACK_TYPE_VERIFY_SUCCESS_RESPONSE:
				emit_signal("connect_success")
			elif unpack["datapack_type"] == DATAPACK_TYPE_HEARTBEAT_RESPONSE:
				pass
			else:
				var data = unpack["data"]
				emit_signal("data_received", data)


func _on_ws_server_close_request(code: int, reason: String):
	if use_log:
		print("_on_ws_server_close_request")
	pass


func _on_timer_timeout():
	if self._connected_status < 0:
		return
	self._send_heartbeat()
