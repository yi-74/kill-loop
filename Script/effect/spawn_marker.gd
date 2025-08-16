extends Node2D

# --- 接收来自 Spawner 的参数 ---
var spawn_duration: float = 1.0
var enemy_scene: PackedScene # 要生成的敌人场景
var spawn_position: Vector2

func _ready() -> void:
	# 初始时完全透明
	modulate.a = 0.0
	
	# 创建一个 Tween 来控制透明度动画
	var tween = create_tween()
	# 使用您指定的 ease_out_cubic 缓动曲线
	tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# 编排动画：在 spawn_duration 秒内，将透明度从 0 变为 1
	tween.tween_property(self, "modulate:a", 1.0, spawn_duration)
	
	# 等待动画完成
	await tween.finished
	
	# --- 动画完成后，生成敌人 ---
	var enemy_instance = enemy_scene.instantiate()
	get_parent().add_child(enemy_instance)
	enemy_instance.global_position = spawn_position
	
	# 自己消失
	queue_free()
