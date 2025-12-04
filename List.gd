# List.gd
extends Control

@onready var container = $ItemsContainer

func _ready():
	$RefreshButton.pressed.connect(refresh)
	refresh()

func refresh():
	for child in container.get_children():
		child.queue_free()
	
	for row in Database.get_all():
		var item = preload("res://src/Scenes/item_row.tscn").instantiate()  # adjust path if needed
		item.get_node("ProductName").text = row[1]  # name
		
		if FileAccess.file_exists(row[3]):  # photo_path
			var tex = ImageTexture.create_from_image(Image.load_from_file(row[3]))
			item.get_node("Thumbnail").texture = tex
		
		# Pass data via Global singleton
		item.get_node("ViewButton").pressed.connect(func():
			Global.barcode_to_show = row[2]   # barcode_path
			Global.title_to_show = row[1]     # name
			get_tree().change_scene_to_file("res://Viewer.tscn")
		)
		
		container.add_child(item)
