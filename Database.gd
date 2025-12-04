extends Node

var db

func _ready():
	var sqlite = preload("res://addons/godot-sqlite/gdsqlite.gdextension")  # this path works with the AssetLib version
	db = sqlite.new()
	db.path = "user://barcodes.db"
	db.open_db()
	
	var table = """
	CREATE TABLE IF NOT EXISTS items (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		barcode TEXT UNIQUE,
		name TEXT,
		date TEXT,
		barcode_path TEXT,
		photo_path TEXT
	);
	"""
	db.query(table)

func save_item(barcode: String, name: String, barcode_path: String, photo_path: String):
	db.query("INSERT OR REPLACE INTO items (barcode, name, date, barcode_path, photo_path) VALUES (?, ?, ?, ?, ?)",
		[barcode, name, Time.get_datetime_string_from_system(), barcode_path, photo_path])

func get_all() -> Array:
	db.query("SELECT barcode, name, barcode_path, photo_path FROM items ORDER BY date DESC")
	return db.query_result
