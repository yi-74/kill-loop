# data_manager.gd
extends Node

const SAVE_FILE_PATH = "user://savegame.dat"

var high_score: int = 0
# --- 【新增】记录玩家是否玩过的变量 ---
var has_played_before: bool = false
var settings: Dictionary = {
	"fullscreen": false,
	"language": "zh_CN",
	"music_volume": 0.0,
	"sfx_volume": 0.0
}

# 在 load_data() 中，加载 settings
# 在 save_data() 中，保存 settings

# --- 新增应用设置的函数 ---
func apply_all_settings():
	# ... (全屏和语言的逻辑不变) ...
	
	# --- 【核心修正】应用音量到不同的总线 ---
	# linear_to_db() 是一个内置函数，能把 0-1 的线性值，转换为 -80 到 0 的分贝(db)值
	# AudioServer.get_bus_index() 用来通过名字找到总线的索引
	
	# 设置音乐总线的音量
	var music_bus_idx = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(settings.music_volume / 100.0))
	
	# 设置音效总线的音量
	var sfx_bus_idx = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(settings.sfx_volume / 100.0))



func _ready() -> void:
	load_data()



# --- 【新】一个专门用于调试的、只重置分数的函数 ---
func debug_reset_all_data():
	print("--- DEBUG: 正在执行分数重置 ---")
	
	# a) 只重置分数
	high_score = 0
	
	# b) 我们不再需要 has_played_before 这个变量了
	#    可以从脚本顶部、load_data 和 save_data 中都删除它
	
	# c) 将重置后的分数，保存到存档文件中
	save_data()
	
	print("--- DEBUG: 分数已重置为 0 并保存。---")



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
