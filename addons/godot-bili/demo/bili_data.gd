# 用于保存 bili 数据的节点，例如用户信息和头像
# 可以考虑做一个定时清理
extends Node

# 用户信息请求完成 user_info : Dict
signal user_info_completed(user_info)
# 用户头像请求完成 user_face : Texture
signal user_face_completed(user_face)

# key 都是 uid
# 从 uid 到 userinfo
var users_info := {}
var users_face_image := {}
var users_face_texture := {}

var _bili_info_request := BiliInfoRequest.new()

# 请求user的data，先请求用户信息user_info 后请求头像user_face
func request_user_data(uid:int):
	if not users_info.has(uid):
		var request = _get_bili_info_request()
		request.request_user_info(uid)


func get_user_info(uid:int):
	if not users_info.has(uid):
		return null
	return users_info[uid]


func get_user_face_texture(uid:int) -> Texture:
	if not users_face_texture.has(uid):
		return null
	return users_face_texture[uid]


func get_user_face_image(uid:int) -> Image:
	if not users_face_image.has(uid):
		return null
	return users_face_image[uid]


func clear_data():
	users_info.clear()
	users_face_image.clear()
	users_face_texture.clear()


func _ready():
	_bili_info_request.connect("info_completed", self, "_on_bili_info_completed")
	add_child(_bili_info_request)


# 得到一个可用的 bili_info_request
func _get_bili_info_request() -> BiliInfoRequest:
	return _bili_info_request


func _get_image_request() -> ImageRequest:
	for child in get_children():
		if child is ImageRequest:
			if child.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
				return child

	var request = ImageRequest.new()
	request.connect("image_completed", self, "_on_image_completed")
	add_child(request, true)
	return request


func _on_bili_info_completed(dict: Dictionary, type):
	var uid = dict["mid"]

	if type == "user_info":
		users_info[uid] = dict
		emit_signal("user_info_completed", dict)
		if not users_face_image.has(uid):
			var face_url = users_info[uid]["face"]
			var request = _get_image_request()
			request.request_image(face_url, uid)
	else:
		push_error("type is not user_info")


func _on_image_completed(image: Image, uid: int):
	users_face_image[uid] = image
	var texture = image2texture(image)
	users_face_texture[uid] = texture
	emit_signal("user_face_completed", texture)


static func image2texture(image: Image) -> Texture:
	var texture := ImageTexture.new()
	texture.create_from_image(image)
	return texture
