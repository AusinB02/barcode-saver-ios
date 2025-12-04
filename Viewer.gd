# Viewer.gd
extends Control

@onready var img = $BarcodeImage
@onready var label = $TitleLabel

func _ready():
	$BackButton.pressed.connect(func():
		get_tree().change_scene_to_file("res://main.tscn")
	)
	
	if Global.barcode_to_show != "":
		img.texture = ImageTexture.create_from_image(Image.load_from_file(Global.barcode_to_show))
		label.text = Global.title_to_show
	
	# Keep screen on (Godot 4.5+)
	DisplayServer.screen_set_keep_on(true)
