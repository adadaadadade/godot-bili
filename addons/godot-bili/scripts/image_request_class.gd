# 请求图片的HttpRequest类, 因为godot的原因现还不能加载gif图片，github上是有项目可以支持gif图片，但是很麻烦，不能直接作为插件是使用
extends HTTPRequest
class_name ImageRequest

# 完成时返回image 和 uid
signal image_completed(image, uid)

var url
var uid


func _ready():
	use_threads = true
	connect("request_completed", self, "_http_request_completed")


func request_image(image_url: String, uid: int):
	while get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		yield(get_tree(), "idle_frame")
	# cdn 网站可以规定请求的格式
	image_url += "@.png"
	var error = request(image_url)
	if error != OK:
		push_error("HTTP 请求发生了错误。")
	#
	self.url = image_url
	self.uid = uid


# 将在 HTTP 请求完成时调用。
func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var extension = self.url.get_extension()
	var error
	match extension:
		"png":
			error = image.load_png_from_buffer(body)
		_:
			push_error("cant make image from " + str(extension))
			return
	if error != OK:
		push_error("无法加载图片。")
		return

	emit_signal("image_completed", image, self.uid)
