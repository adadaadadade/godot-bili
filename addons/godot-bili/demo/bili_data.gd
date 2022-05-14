extends Node

# 从 uid 到 userinfo
var users_info := {}
var users_face_image := {}
var users_face_texture := {}


var _bili_info_request := BiliInfoRequest.new()

func _ready():
	_bili_info_request.connect("info_completed", self, "_on_bili_info_completed")
	add_child(_bili_info_request)

# 得到一个可用的 bili_info_request
func get_bili_info_request() -> BiliInfoRequest:
	return _bili_info_request


func get_image_request() -> ImageRequest:
	for child in get_children():
		if child is ImageRequest:
			if child.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
				return child

	var request = ImageRequest.new()
	request.connect("image_completed", self, "_on_image_completed")
	add_child(request, true)
	return request


func clear_data():
	users_info.clear()
	users_face_image.clear()
	users_face_texture.clear()

func _on_BiliLiveParser_danmu(dict):
	var uid = dict["uid"]

	if not users_info.has(uid):
		var request = get_bili_info_request()
		request.request_user_info(uid)

func _on_BiliLiveParser_gift(dict):
	var uid = dict["uid"]

	if not users_info.has(uid):
		var request = get_bili_info_request()
		request.request_user_info(uid)


func _on_bili_info_completed(dict: Dictionary, type):
	var uid = dict["mid"]

	if type == "user_info":
		users_info[uid] = dict

	if not users_face_image.has(uid):
		var face_url = users_info[uid]["face"]
		var request = get_image_request()
		request.request_image(face_url, uid)


func _on_image_completed(image: Image, uid: int):
	users_face_image[uid] = image
	users_face_texture[uid] = image2texture(image)
	#print(users_face_image)
	  # 将图片显示到 TextureRect 节点上。
	var texture_rect = TextureRect.new()
	add_child(texture_rect)
	texture_rect.texture = users_face_texture[uid]


static func image2texture(image: Image) -> Texture:
	var texture := ImageTexture.new()
	texture.create_from_image(image)
	return texture
