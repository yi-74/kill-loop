# test_velocity.gd
extends RigidBody2D

func _input(event: InputEvent) -> void:
	# 如果按下 R 键
	if Input.is_action_just_pressed("ui_right"): # "ui_right" 默认绑定了 D 键和右箭头
		print("指令：高速向右！")
		linear_velocity = Vector2(1500, 0)

	# 如果按下 L 键
	if Input.is_action_just_pressed("ui_left"): # "ui_left" 默认绑定了 A 键和左箭头
		print("指令：慢速向左！")
		linear_velocity = Vector2(-300, 0)
