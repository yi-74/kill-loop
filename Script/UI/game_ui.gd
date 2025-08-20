extends Control

@onready var score_label: Label = $ScoreLabel
@onready var high_score_label: Label = $HighScoreLabel
# 获取 Label 节点的引用
@onready var speed_label: Label = $SpeedLabel
@onready var combo_lost_anim: AnimationPlayer = $ComboLostAnimationPlayer
# ... (您现有的 speed_label 的代码) ...
@onready var energy_bar_1: TextureProgressBar = $BoxContainer/EnergyBar
@onready var energy_bar_2: TextureProgressBar = $BoxContainer/EnergyBar2
@onready var energy_bar_3: TextureProgressBar = $BoxContainer/EnergyBar3
# 注意：为了能正确获取，您可能需要手动给场景树里的三个能量条改名
@onready var combo_label: Label = $ComboLabel
@onready var game_timer_label: Label = $GameTimerLabel

var is_high_score_broken: bool = false


func _ready():
	# 游戏开始时，显示历史最高分
	high_score_label.text = "HI: " + str(DataManager.high_score)
	return



func on_score_updated(new_score: int):
	# 1. 更新当前分数的显示
	score_label.text = str(new_score)
	
	# 2. 获取最新的历史最高分
	var current_high_score = DataManager.high_score
	
	# 3. 更新历史最高分的显示
	high_score_label.text = "HI: " + str(current_high_score)
	
	# 4. 根据当前分数和历史最高分的关系，来决定颜色
	if new_score >= current_high_score:
		# 如果当前分数已经达到或超过最高分，就用青色
		score_label.add_theme_color_override("font_color", Color("00ffff")) # 青色
	else:
		# 否则，用红色
		score_label.add_theme_color_override("font_color", Color("ff3b30")) # 红色



func update_game_timer(new_time_float: float) -> void:
	# --- 1. 手动截断，保留两位小数 ---
	# a) 将秒数乘以 100，例如 83.518 -> 8351.8
	var multiplied = new_time_float * 100.0
	# b) 取整数部分，砍掉所有多余的小数，得到 8351
	var truncated_int = int(multiplied)
	# c) 再除以 100.0，得到精确截断后的浮点数 83.51
	var truncated_float = truncated_int / 100.0
	
	# --- 2. 使用字符串格式化，强制显示两位小数 ---
	#    "%.2f" 会强制让数字以保留两位小数的形式显示
	#    如果数字本身只有一位小数（如 2.6），它会自动在末尾补一个 0，变成 "2.60"
	#    如果数字是整数（如 27.0），它会自动补上 ".00"，变成 "27.00"
	var formatted_string = "%.2f" % truncated_float
	
	# 3. 更新 Label 的文本
	game_timer_label.text = formatted_string



func update_speed_label(new_speed: float) -> void:
	var scaled_speed = new_speed / 10.0  # 1. 将浮点数速度值除以 10
	var final_speed_int = int(scaled_speed)  # 2. 使用 int() 函数将结果转换为整数（它会自动去掉所有小数）
	speed_label.text = "Speed: " + str(final_speed_int)  # 3. 更新 Label 的文本


# 一个函数，用来接收一个总能量值 (0-300)，并更新所有能量条
func update_energy_display(total_energy: float):
	# 将总能量分配到三个能量条上
	energy_bar_1.value = clamp(total_energy, 0, 100)
	energy_bar_2.value = clamp(total_energy - 100, 0, 100)
	energy_bar_3.value = clamp(total_energy - 200, 0, 100)


# --- 新增：接收连击更新的函数 ---
func on_combo_updated(combo_count: int):
	combo_label.text = str(combo_count)


# --- 新增：接收连击中断的函数 ---
func on_combo_lost():
	# 播放 "Combo Lost" 动画
	#combo_lost_anim.play("show_and_fade")
	return
	
