# data_stats.gd
extends Control

@onready var high_score_value: Label = %HighScoreValue
@onready var total_time_value: Label = %TotalTimeValue
@onready var total_kills_value: Label = %TotalKillsValue
@onready var max_kills_value: Label = %MaxKillsValue
@onready var max_combo_value: Label = %MaxComboValue
@onready var back_button: Button = %BackButton
@onready var max_time_value: Label = %MaxTimeValue
@onready var background_animation: AnimatedSprite2D = $BackgroundAnimation


func _ready() -> void:
	back_button.pressed.connect(queue_free)
	
	# 当页面显示时，从 DataManager 读取并显示所有数据
	high_score_value.text = str(DataManager.high_score)
	total_time_value.text = format_time(DataManager.total_play_time)
	total_kills_value.text = str(DataManager.total_kills)
	max_kills_value.text = str(DataManager.max_kills_per_run)
	max_combo_value.text = str(DataManager.max_combo_per_run)
	max_time_value.text = format_time(DataManager.max_survival_time)
	
	# --- 【新增】在所有数据都准备好后，开始播放背景动画 ---
	if is_instance_valid(background_animation):
		background_animation.play("default")
		
	# 触发成就：这是你的成就！还有谢谢你玩我的游戏！
	SteamManager.unlock_achievement("ACH_MISC_OPEN_STATS")


# 一个格式化时间的辅助函数
func format_time(time_in_seconds: float) -> String:
	# 1. 使用字符串格式化，%.2f 会将浮点数格式化为保留两位小数的字符串
	#    (这个技巧我们之前在实时计时器里用过)
	var formatted_seconds = "%.2f" % time_in_seconds
	
	# 2. 在后面拼接上 "s" 单位
	return formatted_seconds + "s"
