# Godot Bili

直接使用websocket连接B站直播间。

现已实现连接B站直播间弹幕和下载头像图片。

res://addons/godot-bili/demo 下有演示，使用时连接bili_live_parser的信号，然后自己解析弹幕具体内容应该就行。

demo 默认会在 user://bili_logs/<房间号>/<get_datetime格式的日期>.log 生成日志。若想要分析格式，可以查看生成的日志。

# Demo
- Demo  # 主节点
    - BiliLive  # 连接直播间的节点，修改房间号即可连接直播间
        - LiveLogger    # 直播Logger，默认生成日志
    - BiliLiveParser    # B站信息解释器，会发出弹幕信号、礼物信号等
    - BiliData  # B站数据节点，存储用户信息、头像等

## BiliLive

导出的变量

| 变量名         | 介绍                                       |
| -------------- | ------------------------------------------ |
| room_id        | 连接的房间 id，短id长id都可以              |
| use_wss        | 是否使用 wss, 导出到可执行时可能得设置证书 |
| heartbeat_time | 心跳包发送间隔，一般不需要修改             |

## BiliLiveParser
信号

| 信号名                 | 介绍                                                      |
| ---------------------- | --------------------------------------------------------- |
| danmu                  | 收到弹幕                                                  |
| gift                   | 收到礼物                                                  |
| gift_combo             | 礼物combo                                                 |
| user_enter             | 用户进入                                                  |
| guard_enter            | 舰长进入特效                                              |
| watch_changed          | 观看人数改变                                              |
| super_chat_message     | super chat 这两个应该连接一个就行，好像同一个SC两个都会发 |
| super_chat_message_jpn | super chat 这两个应该连接一个就行，好像同一个SC两个都会发 |
| guard_buy              | 上舰长                                                    |
| fan_like_change        | 粉丝关注                                                  |
| online_rank_count      | 高能榜计数                                                |
| online_rank_v2         | 高能榜 前7变化 大概                                       |
| online_rank_top3       | 高能榜 前三变化                                           |
| hot_rank_changed       | 分区排行变化，例如单机游戏分区                            |
| hot_rank_changed_v2    | 二级分区变化，例如单机游戏下的独立游戏分区                |

具体字典内建议连接到一个人多的直播间自己参看日志内容分析。

## BiliData

函数

| 函数名                | 参数 | 介绍                                                        |
| --------------------- | ---- | ----------------------------------------------------------- |
| request_user_data     | uid  | 请求user的data，先请求用户信息user_info 后请求头像user_face |
| get_user_info         | uid  |                                                             |
| get_user_face_texture | uid  |                                                             |
| get_user_face_image   | uid  |                                                             |

信号

| 信号名              | 参数              | 介绍             |
| ------------------- | ----------------- | ---------------- |
| user_info_completed | user_info:Dict    | 用户信息请求完成 |
| user_face_completed | user_face:Textrue | 用户头像请求完成 |



# 已知的问题
- b站HTTP API 有反爬虫机制，用户数据访问速度不能快过1秒1个，否则会被关小黑屋。

# 参考
https://github.com/vmjcv/godot_game

https://github.com/lovelyyoshino/Bilibili-Live-API