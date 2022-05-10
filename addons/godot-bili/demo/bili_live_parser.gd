# 连接 BiliLive 的data_receive信号，再分析激活自己的信号
extends Node

signal danmu(dict)
signal gift(dict)

### cmd字段消息类型
# 弹幕消息
const DANMU_MSG = "DANMU_MSG"
#
const INTERACT_WORD = "INTERACT_WORD"
#
const WATCHED_CHANGE = "WATCHED_CHANGE"
# 欢迎xxx老爷
const WELCOME_GUARD = "WELCOME_GUARD"
# 欢迎舰长进入房间
const ENTRY_EFFECT = "ENTRY_EFFECT"
# 欢迎xxx进入房间
const WELCOME = "WELCOME"
# 二个都是SC留言
const SUPER_CHAT_MESSAGE_JPN = "SUPER_CHAT_MESSAGE_JPN"
const SUPER_CHAT_MESSAGE = "SUPER_CHAT_MESSAGE"
# 投喂礼物
const SEND_GIFT = "SEND_GIFT"
# 连击礼物
const COMBO_SEND = "COMBO_SEND"
# 天选之人开始完整信息
const ANCHOR_LOT_START = "ANCHOR_LOT_START"
# 天选之人获奖id
const ANCHOR_LOT_END = "ANCHOR_LOT_END"
# 天选之人获奖完整信息
const ANCHOR_LOT_AWARD = "ANCHOR_LOT_AWARD"
# 上舰长
const GUARD_BUY = "GUARD_BUY"
# 续费了舰长
const USER_TOAST_MSG = "USER_TOAST_MSG"
# 在本房间续费了舰长
const NOTICE_MSG = "NOTICE_MSG"
# 小时榜变动
const ACTIVITY_BANNER_UPDATE_V2 = "ACTIVITY_BANNER_UPDATE_V2"
# 粉丝关注变动
const ROOM_REAL_TIME_MESSAGE_UPDATE = "ROOM_REAL_TIME_MESSAGE_UPDATE"


export(NodePath) var live_path setget set_live_path

var _live: Node


func set_live_path(val: NodePath):
	if not is_inside_tree():
		yield(self, "ready")
	_live = get_node(val)
	if is_instance_valid(_live):
		_live.connect("connect_success", self, "_on_live_connect_success")
		_live.connect("data_received", self, "_on_live_data_received")


func _on_live_connect_success():
	pass


func _on_live_data_received(data: Dictionary):
	# 认证连接返回的 data 中没有 cmd 字段
	if not data.has("cmd"):
		return
	var cmd = data["cmd"]
	var dict = {}
	match cmd:
		DANMU_MSG:
			var info = data["info"]
			dict["msg"] = info[1]
			var user_info = info[2]
			dict["uid"] = user_info[0]
			dict["uname"] = user_info[1]
			var medal_info = info[3]
			
			emit_signal("danmu", dict)
		SEND_GIFT:
			dict = data
			emit_signal("gift", dict)
		_:
			pass
	
	#print(dict)
	
