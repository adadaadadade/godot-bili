# 日志器
extends Node
class_name Logger

export(String) var file_path setget set_file_path

var _file := File.new()


func add_line(line: String):
	_file.store_line(line)


func set_file_path(val: String):
	var err :=  _file.open(val, File.WRITE)
	if err != OK:
		printerr("Open file error file path :" + val)
	else:
		file_path = val


func _exit_tree():
	_file.close()
