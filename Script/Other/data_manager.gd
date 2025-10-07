# data_manager.gd
extends Node

const SAVE_FILE_PATH = "user://savegame.dat"

var high_score: int = 0
# --- 【新增】记录玩家是否玩过的变量 ---
var has_played_before: bool = false



func _ready() -> void:
	load_data()



func load_data() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var data = file.get_var(true) # 使用 true 参数来允许加载自定义对象
		file.close()
		if data is Dictionary:
			high_score = data.get("high_score", 0)
			# --- 【新增】加载“是否玩过”的记录 ---
			has_played_before = data.get("has_played_before", false)
	print("DataManager: 已加载数据。最高分: ", high_score, " | 是否玩过: ", has_played_before)




func save_data() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	# --- 【新增】将“是否玩过”也保存起来 ---
	var data = {
		"high_score": high_score,
		"has_played_before": has_played_before
	}
	file.store_var(data, true)
	file.close()
	print("DataManager: 已保存数据。")



func report_new_score(score: int) -> void:
	if score > high_score:
		high_score = score
		save_data()



# --- 【新增】一个专门用来标记“已玩过”的函数 ---
func set_played_before():
	if not has_played_before:
		has_played_before = true
		save_data()
