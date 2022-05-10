tool
extends EditorPlugin

const BiliInfoRequest = preload("scripts/bili_info_request_class.gd")
const BiliLive = preload("scripts/bili_live_class.gd")


func _enter_tree():
#	add_custom_type("BiliInfoRequest", "HTTPRequest", BiliInfoRequest, get_icon("HTTPRequest"))
#	add_custom_type("BiliLive", "Node", BiliLive, get_icon("Node"))
	add_autoload_singleton("BiliUtils", "res://addons/godot-bili/scripts/bili_utils.gd")


func _exit_tree():
#	remove_custom_type("BiliInfoRequest")
#	remove_custom_type("BiliLive")
	remove_autoload_singleton("BiliUtils")


func get_icon(node_name: String):
	return get_editor_interface().get_base_control().get_icon(node_name, "EditorIcons")
