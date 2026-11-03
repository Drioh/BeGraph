extends Node3D

@onready var player: CharacterBody3D = $Player3D

func _ready() -> void:
	var btn_hub := get_node_or_null("%BtnHub") as Button
	if btn_hub: btn_hub.pressed.connect(func(): _teleport(Vector3(0, 0.5, 0)))

	var btn_st1 := get_node_or_null("%BtnSt1") as Button
	if btn_st1: btn_st1.pressed.connect(func(): _teleport(Vector3(-25, 0.5, -20)))

	var btn_st2 := get_node_or_null("%BtnSt2") as Button
	if btn_st2: btn_st2.pressed.connect(func(): _teleport(Vector3(25, 0.5, -20)))

	var btn_st3 := get_node_or_null("%BtnSt3") as Button
	if btn_st3: btn_st3.pressed.connect(func(): _teleport(Vector3(-25, 0.5, 30)))

	var btn_st4 := get_node_or_null("%BtnSt4") as Button
	if btn_st4: btn_st4.pressed.connect(func(): _teleport(Vector3(25, 0.5, 30)))

	var btn_st5 := get_node_or_null("%BtnSt5") as Button
	if btn_st5: btn_st5.pressed.connect(func(): _teleport(Vector3(0, 0.5, 40)))

	var btn_switch := get_node_or_null("%BtnSwitch2D") as Button
	if btn_switch:
		btn_switch.pressed.connect(func():
			get_tree().change_scene_to_file("res://gym_2d/gym_2d.tscn")
		)

func _teleport(pos: Vector3) -> void:
	if player:
		player.global_position = pos
		player.velocity = Vector3.ZERO
