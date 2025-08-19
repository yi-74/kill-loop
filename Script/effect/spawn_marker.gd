extends Node2D

# --- 接收来自 Spawner 的参数 ---
var spawn_duration: float = 1.0
var enemy_scene: PackedScene # 要生成的敌人场景
var spawn_position: Vector2
var patrol_path_to_assign: Path2D = null
var path_manager_ref = null

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
	var enemy_instance = enemy_scene.instantiate()
	get_parent().add_child(enemy_instance)
	
	# 如果是巡逻敌人，就调用它的初始化函数
	if enemy_instance.has_method("initialize"):
		enemy_instance.initialize(patrol_path_to_assign, path_manager_ref)
	else:
		# 其他敌人，正常设置位置
		enemy_instance.global_position = spawn_position
	
	queue_free()
