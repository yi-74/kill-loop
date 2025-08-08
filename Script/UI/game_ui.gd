extends Control

# 获取 Label 节点的引用
@onready var speed_label: Label = $SpeedLabel
@onready var combo_lost_anim: AnimationPlayer = $ComboLostAnimationPlayer
# ... (您现有的 speed_label 的代码) ...
@onready var energy_bar_1: TextureProgressBar = $BoxContainer/EnergyBar
@onready var energy_bar_2: TextureProgressBar = $BoxContainer/EnergyBar2
@onready var energy_bar_3: TextureProgressBar = $BoxContainer/EnergyBar3
# 注意：为了能正确获取，您可能需要手动给场景树里的三个能量条改名
@onready var combo_label: Label = $ComboLabel


func _ready():
	# 初始时隐藏 "Combo Lost" 提示
	#combo_lost_anim.play("RESET")
	return

# 这个函数会接收从 PlayerBall 广播过来的速度值
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
	
