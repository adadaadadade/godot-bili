# BiliLive 日志输出， 默认路径在 user://bili_logs/<房间号>/<get_datetime格式的日期>.txt
extends Logger
class_name BiliLiveLogger

export(NodePath) var live_path setget set_live_path
export(bool) var auto_filename = true
export(String, DIR) var log_dir = "user://bili_logs"
export(String) var log_tail = ".txt"


var _live: Node


func _ready():
	if auto_filename:
		var dir_path = log_dir + "/" + str(_live.room_id)
		var dir = Directory.new()
		if not dir.dir_exists(dir_path):
			dir.make_dir_recursive(dir_path)
		# Time 是3.5新加入的， 3.4可以改用OS.get_datetime() 再转为字符串
		var file_name = datetime2str(OS.get_datetime()) + log_tail
		#var file_name = Time.get_datetime_string_from_system() + log_tail
		var file_path = dir_path + "/" + file_name
		set_file_path(file_path)


func set_live_path(val: NodePath):
	if not is_inside_tree():
		yield(self, "tree_entered")
	_live = get_node(val)
	if is_instance_valid(_live):
		_live.connect("connect_success", self, "_on_live_connect_success")
		_live.connect("data_received", self, "_on_live_data_received")
		pass


func _on_live_connect_success():
	pass


func _on_live_data_received(data: Dictionary):
	add_line(to_json(data))


static func datetime2str(datetime:Dictionary) -> String:
	var ret = ""
	ret += str(datetime["year"]) + "-"
	ret += str(int2str(datetime["month"])) + "-"
	ret += str(int2str(datetime["day"])) + "T"
	ret += str(int2str(datetime["hour"])) + ":"
	ret += str(int2str(datetime["minute"])) + ":"
	ret += str(int2str(datetime["second"]))
	return ret

static func int2str(val:int, length:int=2) -> String:
	var ret = str(val)
	while ret.length() < length:
		ret = '0' + ret
	return ret
