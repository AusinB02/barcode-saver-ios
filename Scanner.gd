# Scanner.gd
extends Control

@onready var status = $StatusLabel
@onready var button = $ScanButton

func _ready():
	button.pressed.connect(_start_scan)

func _start_scan():
	status.text = "Choose or take a photo..."
	var dialog = FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = PackedStringArray(["*.png", "*.jpg", "*.jpeg"])
	add_child(dialog)
	dialog.popup_centered_ratio(0.8)
	dialog.file_selected.connect(_photo_selected)

func _photo_selected(path: String):
	status.text = "Decoding barcode..."
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_decode_done.bind(path))
	
	# Upload to ZXing decoder
	var file = FileAccess.open(path, FileAccess.READ)
	var bytes = file.get_buffer(file.get_length())
	var boundary = "----GodotBoundary"
	var body = PackedByteArray()
	body.append_array(("--" + boundary + "\r\n").to_utf8_buffer())
	body.append_array("Content-Disposition: form-data; name=\"f\"; filename=\"barcode.jpg\"\r\n".to_utf8_buffer())
	body.append_array("Content-Type: image/jpeg\r\n\r\n".to_utf8_buffer())
	body.append_array(bytes)
	body.append_array(("\r\n--" + boundary + "--\r\n").to_utf8_buffer())
	
	var headers = ["Content-Type: multipart/form-data; boundary=" + boundary]
	http.request("https://zxing.org/w/decode", headers, HTTPClient.METHOD_POST, body)

func _on_decode_done(_result, response_code, _headers, body, photo_path):
	if response_code != 200:
		status.text = "Decode failed"
		return
	
	var text = body.get_string_from_utf8()
	var barcode = text.get_slice("Raw text:</b> ", 1).get_slice("<", 0).strip_edges()
	if barcode == "":
		status.text = "No barcode found"
		return
	
	status.text = "Found: " + barcode
	_fetch_product(barcode, photo_path)

func _fetch_product(barcode: String, photo_path: String):
	var http = HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_product_done.bind(barcode, photo_path))
	http.request("https://world.openfoodfacts.org/api/v0/product/" + barcode + ".json")

func _on_product_done(_result, _code, _headers, body, barcode, photo_path):
	var json = JSON.parse_string(body.get_string_from_utf8())
	var name = "Unknown Item"
	if json and json.status == 1 and json.product.product_name:
		name = json.product.product_name
	
	# === FIXED QR CODE GENERATION (AssetLib plugin) ===
	var qr = preload("res://addons/qr_code/qr_code.gd").new()
	qr.error_correction = qr.ERROR_CORRECTION_LOW
	qr.encode_string(barcode)
	
	var module_size = 10
	var size = qr.modules.size() * module_size
	var img = Image.create(size, size, false, Image.FORMAT_RGB8)
	img.fill(Color.WHITE)
	for y in qr.modules.size():
		for x in qr.modules.size():
			if qr.modules[y][x]:
				img.fill_rect(Rect2(x * module_size, y * module_size, module_size, module_size), Color.BLACK)
	
	# Save files
	DirAccess.make_dir_absolute("user://barcodes")
	DirAccess.make_dir_absolute("user://photos")
	
	var barcode_path = "user://barcodes/" + barcode + ".png"
	var thumb_path = "user://photos/" + barcode + ".jpg"
	
	img.save_png(barcode_path)
	
	# Copy the original photo as thumbnail
	var photo_bytes = FileAccess.get_file_as_bytes(photo_path)
	FileAccess.open(thumb_path, FileAccess.WRITE).store_buffer(photo_bytes)
	
	Database.save_item(barcode, name, barcode_path, thumb_path)
	status.text = "Saved! → " + name
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://main.tscn")
