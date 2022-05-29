# 连接 BiliLive 的data_receive信号，再分析激活自己的信号
extends Node

# 收到弹幕
signal danmu(dict)
# 收到礼物
signal gift(dict)
# 礼物combo
signal gift_combo(dict)
# 用户进入
signal user_enter(dict)
# 舰长进入特效
signal guard_enter(dict)
# 观看人数改变
signal watch_changed(dict)
# super chat 这两个应该连接一个就行，好像同一个SC两个都会发
signal super_chat_message(dict)
signal super_chat_message_jpn(dict)
# 上舰长
signal guard_buy(dict)
# 粉丝关注
signal fan_like_change(dict)
# 高能榜计数
signal online_rank_count(dict)
# 高能榜 前7变化 大概
signal online_rank_v2(dict)
# 高能榜 前三变化
signal online_rank_top3(dict)
# 分区排行变化，例如单机游戏分区
signal hot_rank_changed(dict)
# 二级分区变化，例如单机游戏下的独立游戏分区
signal hot_rank_changed_v2(dict)

### cmd字段消息类型，有些B站已经弃用，建议连接一个人数多的直播间，查看log文件再使用
# 弹幕消息
const DANMU_MSG = "DANMU_MSG"
# 进入房间
const INTERACT_WORD = "INTERACT_WORD"
# 直播开始
const LIVE = "LIVE"
# 主播准备中
const PREPARING = "PREPARING"
# 观看人数改变
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
# 
const USER_TOAST_MSG = "USER_TOAST_MSG"
# 频道广播
const NOTICE_MSG = "NOTICE_MSG"
# 小时榜变动
const ACTIVITY_BANNER_UPDATE_V2 = "ACTIVITY_BANNER_UPDATE_V2"
# 粉丝关注变动
const ROOM_REAL_TIME_MESSAGE_UPDATE = "ROOM_REAL_TIME_MESSAGE_UPDATE"
# 高能榜计数
const ONLINE_RANK_COUNT = "ONLINE_RANK_COUNT"
# 高能榜排名，不过好像就只有7个
const ONLINE_RANK_V2 = "ONLINE_RANK_V2"
# 高能榜前三变化
const ONLINE_RANK_TOP3 = "ONLINE_RANK_TOP3"
# 分区排行变化，例如单机游戏分区
const HOT_RANK_CHANGED = "HOT_RANK_CHANGED"
# 二级分区变化，例如单机游戏下的独立游戏分区
const HOT_RANK_CHANGED_V2 = "HOT_RANK_CHANGED_V2"


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
			#print(dict)
			emit_signal("danmu", dict)
		SEND_GIFT:
			dict = data["data"]
			emit_signal("gift", dict)
		COMBO_SEND:
			dict = data["data"]
			emit_signal("gift_combo", dict)
		INTERACT_WORD:
			dict = data["data"]
			emit_signal("user_enter", dict)
		ENTRY_EFFECT:
			dict = data["data"]
			emit_signal("guard_enter", dict)
		WATCHED_CHANGE:
			dict = data["data"]
			emit_signal("watch_changed", dict)
		SUPER_CHAT_MESSAGE:
			dict = data["data"]
			emit_signal("super_chat_message", dict)
		SUPER_CHAT_MESSAGE_JPN:
			dict = data["data"]
			emit_signal("super_chat_message_jpn", dict)
		GUARD_BUY:
			dict = data["data"]
			emit_signal("guard_buy", dict)
		ROOM_REAL_TIME_MESSAGE_UPDATE:
			dict = data["data"]
			emit_signal("fan_like_change", dict)
		ONLINE_RANK_COUNT:
			dict = data["data"]
			emit_signal("online_rank_count", dict)
		ONLINE_RANK_V2:
			dict = data["data"]
			emit_signal("online_rank_v2", dict)
		ONLINE_RANK_TOP3:
			dict = data["data"]
			emit_signal("online_rank_top3", dict)
		HOT_RANK_CHANGED:
			dict = data["data"]
			emit_signal("hot_rank_changed", dict)
		HOT_RANK_CHANGED_V2:
			dict = data["data"]
			emit_signal("hot_rank_changed_v2", dict)
		_:
			pass
	
	#print(dict)
	
