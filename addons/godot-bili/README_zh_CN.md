# godot-bili

尝试使用godot连接B站API，现已实现连接B站直播间弹幕和下载头像图片。

res://addons/godot-bili/demo 下有演示，使用时连接bili_live_parser的信号，然后自己解析弹幕具体内容应该就行。

demo 默认会在 user://bili_logs/<房间号>/<get_datetime格式的日期>.txt 下生成日志。若想要分析格式，可以查看生成的日志。

# 已知的问题
- b站HTTP API 有反爬虫机制，用户数据访问速度不能快过1秒1个，否则会被关小黑屋。

# 参考
https://github.com/vmjcv/godot_game

https://github.com/lovelyyoshino/Bilibili-Live-API