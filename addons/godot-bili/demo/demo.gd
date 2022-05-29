extends Node

onready var bili_data = $BiliData


func _on_BiliLiveParser_danmu(dict):
	print(dict)
	bili_data.request_user_data(dict["uid"])


func _on_BiliData_user_face_completed(user_face):
	# 将图片显示到 TextureRect 节点上。
	var texture_rect = TextureRect.new()
	add_child(texture_rect)
	texture_rect.texture = user_face
