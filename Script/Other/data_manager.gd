# data_manager.gd
extends Node

const SAVE_FILE_PATH = "user://savegame.dat"

var high_score: int = 0
var total_deaths: int = 0
# --- 【新增】记录玩家是否玩过的变量 ---
var has_played_before: bool = false
var settings: Dictionary = {
	"fullscreen": false,
	"language": "en",
	"music_volume": 50.0,
	"sfx_volume": 50.0
}

# --- 【新增】统计数据 ---
var total_play_time: float = 0.0     # 历史总游戏时长 (秒)
var total_kills: int = 0             # 历史总击杀数
var max_kills_per_run: int = 0       # 单局最高击杀数
var max_combo_per_run: int = 0       # 单局最高连击数 (新增，这个很有趣！)
var max_survival_time: float = 0.0   # 单局最高存活时间


# --- 新增应用设置的函数 ---
func apply_all_settings():
	TranslationServer.set_locale(settings.language)
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
	# --- 【新增】在读取存档之前，先探测玩家电脑操作系统的语言！ ---
	# OS.get_locale_language() 会返回语言的两位简写，比如中文是 "zh"，英文是 "en"，日语是 "ja"
	var os_lang = OS.get_locale_language() 
	
	if os_lang == "zh":
		settings["language"] = "zh_CN" # 如果是中文系统，默认语言设为中文
	else:
		settings["language"] = "en"    # 其他所有系统，默认语言设为英文
	# -------------------------------------------------------------
	
	# 然后再执行原本的加载数据逻辑
	load_data()
	
	# --- 【新增】加载完数据后，立刻把语言（以及音量、全屏）应用到游戏中！ ---
	if has_method("apply_all_settings"):
		apply_all_settings()



# --- 终极调试：初始化所有信息 ---
func debug_reset_all_data():
	print("--- DEBUG: 正在执行【核弹级】完全重置 ---")
	
	# 1. 重置核心分数和死亡次数
	high_score = 0
	total_deaths = 0
	
	# 2. 重置所有统计数据
	total_play_time = 0.0
	total_kills = 0
	max_kills_per_run = 0
	max_combo_per_run = 0
	max_survival_time = 0.0
	has_played_before = false
	
	# --- 【核心修正】在重置设置时，动态判断默认语言 ---
	var default_lang = "en"
	if OS.get_locale_language() == "zh":
		default_lang = "zh_CN"
	
	# 3. 重置设置字典
	settings = {
		"fullscreen": false,
		"language": default_lang, # <--- 现在它会根据您的系统自动恢复成正确语言！
		"music_volume": 50.0,
		"sfx_volume": 50.0
	}
	
	# 4. 立即应用这些默认设置
	if has_method("apply_all_settings"):
		apply_all_settings()
	
	# 5. 将这些“干净”的数据覆盖保存到本地存档文件
	save_data()
	
	# --- 【核心新增】呼叫 SteamManager，把 Steam 成就也核弹清零 ---
	if ClassDB.class_exists("SteamManager") or has_node("/root/SteamManager"):
		SteamManager.reset_all_achievements()
	
	# 6. 强制重新加载当前所在的任何场景，刷新UI显示
	get_tree().reload_current_scene()
	
	print("--- DEBUG: 所有数据已彻底初始化，场景已重载！ ---")



func load_data() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		var data = file.get_var(true) # 使用 true 参数来允许加载自定义对象
		file.close()
		if data is Dictionary:
			high_score = data.get("high_score", 0)
			total_deaths = data.get("total_deaths", 0)
			
			# 【重点在这里】：
			# 如果玩家之前手动改过设置并保存了，这里的 data.get("settings") 
			# 就会覆盖掉我们在 _ready 里根据系统探测出的默认 settings！
			# 这完美实现了“尊重玩家自定义设置”！
			var saved_settings = data.get("settings", {})
			for key in saved_settings:
				settings[key] = saved_settings[key]
			
			# --- 【新增】加载“是否玩过”的记录 ---
			has_played_before = data.get("has_played_before", false)
			# 【新增】加载统计数据，如果不存在，则默认为 0
			total_play_time = data.get("total_play_time", 0.0)
			total_kills = data.get("total_kills", 0)
			max_kills_per_run = data.get("max_kills_per_run", 0)
			max_combo_per_run = data.get("max_combo_per_run", 0)
			max_survival_time = data.get("max_survival_time", 0.0)
			
	print("DataManager: 已加载数据。最高分: ", high_score, " | 是否玩过: ", has_played_before, " | 当前语言: ", settings["language"])




func save_data() -> void:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	# --- 【新增】将“是否玩过”也保存起来 ---
	var data = {
		"high_score": high_score,
		"settings": settings,
		"has_played_before": has_played_before,
		"total_deaths": total_deaths,
		# 【新增】保存所有统计数据
		"total_play_time": total_play_time,
		"total_kills": total_kills,
		"max_kills_per_run": max_kills_per_run,
		"max_combo_per_run": max_combo_per_run,
		"max_survival_time": max_survival_time
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


# --- 一个全局的、可被任何地方调用的“切换全屏”函数 ---
func toggle_fullscreen():
	# 1. 直接反转设置中记录的全屏状态
	settings.fullscreen = not settings.fullscreen
	
	# 2. 立刻应用这个新的设置
	apply_all_settings()
	
	# 3. 保存新的设置
	save_data()

func _input(event: InputEvent) -> void:
	# 无论在游戏的哪个角落，只要按下 P 键 (debug_reset)
	if Input.is_action_just_pressed("debug_reset"):
		debug_reset_all_data()


# --- 新增一个专门检查累计成就的函数 ---
func check_cumulative_achievements():
	if total_kills >= 1000:
		SteamManager.unlock_achievement("ACH_KILL_1000_TOTAL")
	if total_play_time >= 600.0:
		SteamManager.unlock_achievement("ACH_SURVIVE_600S_TOTAL")
	if total_deaths >= 30:
		SteamManager.unlock_achievement("ACH_MISC_DIE_30_TOTAL")
