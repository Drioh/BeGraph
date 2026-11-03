extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var st1_node: Node2D = get_node_or_null("Stations/Station1_Patrol")
@onready var st3_node: Node2D = get_node_or_null("Stations/Station3_Tag")

func _ready() -> void:
	# Connect UI jump buttons if present
	var btn_center := get_node_or_null("%BtnCenter") as Button
	if btn_center: btn_center.pressed.connect(func(): _teleport_player(Vector2(0, 0)))

	var btn_st1 := get_node_or_null("%BtnSt1") as Button
	if btn_st1: btn_st1.pressed.connect(func(): _teleport_player(Vector2(-900, -350)))

	var btn_st2 := get_node_or_null("%BtnSt2") as Button
	if btn_st2: btn_st2.pressed.connect(func(): _teleport_player(Vector2(900, -350)))

	var btn_st3 := get_node_or_null("%BtnSt3") as Button
	if btn_st3: btn_st3.pressed.connect(func(): _teleport_player(Vector2(-900, 550)))

	var btn_st4 := get_node_or_null("%BtnSt4") as Button
	if btn_st4: btn_st4.pressed.connect(func(): _teleport_player(Vector2(900, 550)))

	var btn_st5 := get_node_or_null("%BtnSt5") as Button
	if btn_st5: btn_st5.pressed.connect(func(): _teleport_player(Vector2(0, 700)))

	var btn_reset_st3 := get_node_or_null("%BtnResetSt3") as Button
	if btn_reset_st3 and st3_node and st3_node.has_method("reset_tag_game"):
		btn_reset_st3.pressed.connect(st3_node.reset_tag_game)

	var btn_switch_3d := get_node_or_null("%BtnSwitch3D") as Button
	if btn_switch_3d:
		btn_switch_3d.pressed.connect(func():
			get_tree().change_scene_to_file("res://gym_3d/gym_3d.tscn")
		)

func _teleport_player(pos: Vector2) -> void:
	if player:
		player.global_position = pos
		player.velocity = Vector2.ZERO

func _draw() -> void:
	# Draw background grid dots / subtle markings across the gym floor
	var grid_color := Color(0.157, 0.157, 0.157, 0.251)
	for x in range(-1600, 1600, 120):
		draw_line(Vector2(x, -1000), Vector2(x, 1200), grid_color, 4.0)
	for y in range(-1000, 1200, 120):
		draw_line(Vector2(-1600, y), Vector2(1600, y), grid_color, 4.0)
