extends HTTPRequest
class_name ImageRequest

signal image_completed(image, url)

var url

func _ready():
	use_threads = true
	connect("request_completed", self, "_http_request_completed")


func request_image(image_url:String):
	# 执行 HTTP 请求。截止到文档编写时，下面的 URL 会返回 PNG 图片。
	self.url = image_url
	var error = request(image_url)
	if error != OK:
		push_error("HTTP 请求发生了错误。")



# 将在 HTTP 请求完成时调用。
func _http_request_completed(result, response_code, headers, body):
	var image = Image.new()
	var extension = self.url.get_extension()
	var error
	match extension:
		"bmp":
			error = image.load_bmp_from_buffer(body)
		"png":
			error = image.load_png_from_buffer(body)
		"jpg":
			error = image.load_jpg_from_buffer(body)
		"webp":
			error = image.load_webp_from_buffer(body)
		"tga":
			error = image.load_tga_from_buffer(body)
	if error != OK:
		push_error("无法加载图片。")
		return

	emit_signal("image_completed", image, self.url)
