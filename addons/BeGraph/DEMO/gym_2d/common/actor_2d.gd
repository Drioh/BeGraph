@tool
extends CharacterBody2D

@export var radius: float = 16.0:
	set(v):
		radius = v
		queue_redraw()
@export var fill_color: Color = Color(0.9, 0.4, 0.2, 1.0):
	set(v):
		fill_color = v
		queue_redraw()
@export var border_color: Color = Color.WHITE:
	set(v):
		border_color = v
		queue_redraw()

var _prev_safe_pos: Vector2 = Vector2.ZERO

#region proxy
@export var behavior_agent: BehaviorAgent

func _ready() -> void:
	_prev_safe_pos = global_position
	queue_redraw()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint(): return
	
	if _prev_safe_pos == Vector2.ZERO:
		_prev_safe_pos = global_position
		return

	# Prevent behavior node position updates from passing through solid obstacles
	var col := move_and_collide(Vector2.ZERO, true)
	if col:
		global_position = _prev_safe_pos + col.get_normal() * (col.get_depth() + 1.0)
	else:
		_prev_safe_pos = global_position

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, border_color, 2.0, true)
