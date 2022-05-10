extends Node

const request_settings = {
	"use_https": true,
	"proxies": null,
}

const DEFAULT_HEADERS = {
	"User-Agent": "Mozilla/5.0",
	"Referer": "https://www.bilibili.com/",
}

const MESSAGES = {
	"no_sess": "需要提供：SESSDATA（Cookies里头的`SESSDATA`键对应的值）",
	"no_csrf": "需要提供：csrf（Cookies里头的`bili_jct`键对应的值）"
}

var api = get_api()


static func get_api() -> Dictionary:
	var file = File.new()
	file.open("res://addons/godot-bili/data/api.json", file.READ)
	var data = file.get_as_text()
	var json_data = JSON.parse(data)
	file.close()
	return json_data.result


static func bvid2aid(bvid):
	var table = 'fZodR9XQDSUm21yCkr6zBqiveYah8bt4xsWpHnJE7jL5VG3guMTKNPAwcF'
	var tr = {}
	for i in range(58):
		tr[table[i]] = i
	var s = [11, 10, 3, 8, 4, 6]
	var xor = 177451812
	var add = 8728348608
	var r = 0
	for i in range(6):
		r += pow(tr[bvid[s[i]]] * 58,i)
	return (r - add) ^ xor


static func aid2bvid(aid):
	var table = 'fZodR9XQDSUm21yCkr6zBqiveYah8bt4xsWpHnJE7jL5VG3guMTKNPAwcF'
	var tr = {}
	for i in range(58):
		tr[table[i]] = i
	var s = [11, 10, 3, 8, 4, 6]
	var xor = 177451812
	var add = 8728348608


	var x = (aid ^ xor) + add
	var r = ['B','V','1',' ',' ','4',' ','1',' ','7',' ',' ']
	for i in range(6):
		r[s[i]] = table[int(floor(pow(x / 58,i))) % 58]
	return r.join('')


static func read_varint(stream):
	var value = 0
	var position = 0
	var shift = 0
	while true:
		if position >= len(stream):
			break
		var byte = stream[position]
		value += (byte & 0b01111111) << shift
		if byte & 0b10000000 == 0:
			break
		position += 1
		shift += 7
	return [value, position + 1]


static func get_method_by_api(api_dict:Dictionary) -> int:
	var method_string = api_dict["method"]
	if method_string == "GET":
		return HTTPClient.METHOD_GET
	elif method_string == "POST":
		return HTTPClient.METHOD_POST
	elif method_string == "DELETE":
		return HTTPClient.METHOD_DELETE
	
	return -1


# 给url加上参数 api_dict通过get_api_dict获取， params_dict为参数名对应列表
static func url_add_params(api_dict:Dictionary, params_dict:Dictionary) -> String:
	var params_api : Dictionary = api_dict["params"]
	var url :String = api_dict["url"]
	for key in params_dict:
		if not params_api.has(key):
			return ""
		var deli = "&" if url.find("?") > 0 else "?"
		url += deli + (str(key) + "=" + str(params_dict[key]))
	
	return url

# 得到 api 的 dict
func get_api_dict(keys:PoolStringArray) -> Dictionary:
	if api == null:
		api = get_api()
	
	var dict
	dict = api
	for key in keys:
		dict = dict[key]
	return dict


class BilibiliColor:
	var _color

	func _init(_hex_color = "FFFFFF"):
		self._color = 0
		self.set_hex_color(_hex_color)

	func set_hex_color(_hex_color):
		var hex_color = ""
		if len(_hex_color)==3:
			for i in _hex_color:
				hex_color = hex_color+i+"0"
		var dec = "0x"+hex_color
		hex_color = dec.hex_to_int()
		self._color = hex_color

	func set_rgb_color(r,g,b):
		r=clamp(r,0,255)
		g=clamp(g,0,255)
		b=clamp(b,0,255)

		self._color = (r<<8*2)+(g<<8)+b

	func set_dec_color(color):
		self._color=clamp(color,0,16777215)

	func get_hex_color():
		var h = "%x"%self._color
		h = h.lstrip("0x")
		h = "0".repeat(6-len(h))+h
		return h

	func get_rgb_color():
		var h = get_hex_color()
		var r = ("0x"+h.slice(0,2)).hex_to_int()
		var g = ("0x"+h.slice(2,4)).hex_to_int()
		var b = ("0x"+h.slice(4,6)).hex_to_int()
		return [r,g,b]

	func get_dec_color():
		return self._color

	func _to_string():
		return self.get_hex_color()


class Danmaku:
	const FONT_SIZE_EXTREME_SMALL = 12
	const FONT_SIZE_SUPER_SMALL = 16
	const FONT_SIZE_SMALL = 18
	const FONT_SIZE_NORMAL = 25
	const FONT_SIZE_BIG = 36
	const FONT_SIZE_SUPER_BIG = 45
	const FONT_SIZE_EXTREME_BIG = 64
	const MODE_FLY = 1
	const MODE_TOP = 5
	const MODE_BOTTOM = 4
	const MODE_REVERSE = 6
	const TYPE_NORMAL = 0
	const TYPE_SUBTITLE = 1

	var dm_time
	var send_time
	var crc32_id
	var uid
	var color
	var mode
	var font_size
	var is_sub
	var text
	var weight
	var id
	var id_str
	var action
	var pool
	var attr
	func _init(_text,_dm_time = 0.0,_send_time=OS.get_unix_time()\
	,_crc32_id=null,_color=null,_weight=-1,_id_=-1,_id_str="",\
	_action="",_mode=MODE_FLY,_font_size=FONT_SIZE_NORMAL,\
	_is_sub=false,_pool=-1,_attr=-1):
		dm_time = _dm_time
		send_time = OS.get_datetime_from_unix_time(_send_time)
		crc32_id = _crc32_id
		uid = null
		color = _color if _color else BilibiliColor.new()
		mode = _mode
		font_size = _font_size
		is_sub = _is_sub
		text = _text
		weight = _weight
		id = _id_
		id_str = _id_str
		action = _action
		pool = _pool
		attr = _attr

	func _to_string():
		var ret = "%s, %s, %s" % [self.send_time, self.dm_time, self.text]
		return ret

	func len():
		return len(self.text)


class Verify extends Reference:
	var sessdata
	var csrf

	func _init(_sessdata=null,_csrf=null):
		self.sessdata = _sessdata
		self.csrf = _csrf

	func get_cookies():
		var cookies = []
		if self.has_sess():
			cookies.append("SESSDATA:%s"%self.sessdata)
#			cookies["SESSDATA"] = self.sessdata
		if self.has_csrf():
			cookies.append("bili_jct:%s"%self.csrf)
#			cookies["bili_jct"] = self.csrf
		return cookies

	func has_sess():
		if self.sessdata:
			return true
		else:
			return false

	func has_csrf():
		if self.csrf:
			return true
		else:
			return false

	func check(http_request):
		var ret = {
			"code":-2,
			"message":"",
		}

		if not self.has_sess():
			ret["code"] = -3
			ret["message"] =  "未提供SESSDATA"
		else:
			var api = "https://api.bilibili.com/x/web-interface/archive/like"
			var data = {"bvid": "BV1uv411q7Mv", "like": 1, "csrf": self.csrf}
			var cookie_string = "cookies:"
			for i in get_cookies():
				cookie_string = cookie_string + i +";"
			var error = http_request.request(api, [cookie_string], true, HTTPClient.METHOD_POST, data)
			if error != OK:
				push_error("An error occurred in the HTTP request.")
			# 注意使用这种结构会让游戏进程中断，正式使用的时候可以更换方式
			var request_ret = yield(http_request, "request_completed")
			var result = request_ret[0]
			var response_code= request_ret[1]
			var headers= request_ret[2]
			var body = request_ret[3]
			if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
				var json = JSON.parse(body.get_string_from_utf8())
				if json.code ==-111:
					ret["code"]=-1
					ret["message"]="csrf 校验失败"
				elif json.code ==-101 or json.code == -400:
					ret["code"]=-2
					ret["message"]="SESSDATA值有误"
				else:
					ret["code"]=0
					ret["message"]="0"
			else:
				push_error("Request error")


class CrackUid:
	var __CRCPOLYNOMIAL
	var __crctable
	var __index
	func _init():
		self.__CRCPOLYNOMIAL = 0xEDB88320
		self.__crctable = [].resize(256)
		self.__create_table()
		self.__index = [].resize(4)

	func __create_table():
		for i in range(256):
			var crcreg = i
			for j in range(8):
				if (crcreg & 1) != 0:
					crcreg = self.__CRCPOLYNOMIAL ^ (crcreg >> 1)
				else:
					crcreg >>= 1
			self.__crctable[i] = crcreg

	func __crc32(input_):
		if typeof(input_) != TYPE_STRING:
			input_ = str(input_)
		var crcstart = 0xFFFFFFFF
		var len_ = len(input_)
		for i in range(len_):
			var index = (crcstart ^ ord(input_[i])) & 0xFF
			crcstart = (crcstart >> 8) ^ self.__crctable[index]
		return crcstart

	func __crc32lastindex(input_):
		if typeof(input_) != TYPE_STRING:
			input_ = str(input_)
		var crcstart = 0xFFFFFFFF
		var len_ = len(input_)
		var index = null
		for i in range(len_):
			index = (crcstart ^ ord(input_[i])) & 0xFF
			crcstart = (crcstart >> 8) ^ self.__crctable[index]
		return index

	func __getcrcindex(t):
		for i in range(256):
			if self.__crctable[i] >> 24 == t:
				return i
		return -1


	func __deepCheck(i, index):
		var tc = 0x00
		var str_ = ""
		var hash_ = self.__crc32(i)
		tc = hash_ & 0xFF ^ index[2]
		if not (57 >= tc >= 48):
			return [0]
		str_ += str(tc - 48)
		hash_ = self.__crctable[index[2]] ^ (hash_ >> 8)

		tc = hash_ & 0xFF ^ index[1]
		if not (57 >= tc >= 48):
			return [0]
		str_ += str(tc - 48)
		hash_ = self.__crctable[index[1]] ^ (hash_ >> 8)

		tc = hash_ & 0xFF ^ index[0]
		if not (57 >= tc >= 48):
			return [0]
		str_ += str(tc - 48)
		hash_ = self.__crctable[index[0]] ^ (hash_ >> 8)
		return [1, str_]

	func get_uid(input_):
		var dec = "0x"+input_
		var ht = dec.hex_to_int()^ 0xFFFFFFFF
		var i = 3
		while i >= 0:
			self.__index[3-i] = self.__getcrcindex(ht >> (i*8))
			var snum = self.__crctable[self.__index[3-i]]
			ht ^= snum >> ((3-i)*8)
			i -= 1
		var bbreak = false
		var deepCheckData
		for j in range(10000000):
			var lastindex = self.__crc32lastindex(j)
			if lastindex == self.__index[3]:
				deepCheckData = self.__deepCheck(j, self.__index)
				if deepCheckData[0]:
					bbreak = true
					break
		if not bbreak:
			return -1
		return str(i) + deepCheckData[1]
