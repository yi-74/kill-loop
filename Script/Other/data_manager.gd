# data_manager.gd
extends Node

const SAVE_FILE_PATH = "user://savegame.dat"

var high_score: int = 0

func _ready() -> void:
	load_data()
	
func load_data() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var data = file.get_var()
		file.close()
		high_score = data.get("high_score", 0)
	print("DataManager: 已加载最高分: ", high_score)
	
func save_data() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	var data = {"high_score": high_score}
	file.store_var(data)
	file.close()
	print("DataManager: 已保存最高分: ", high_score)
	
func report_new_score(score: int) -> void:
	if score > high_score:
		high_score = score
		save_data()
