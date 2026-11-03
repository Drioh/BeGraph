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


@export var behavior_agent: BehaviorAgent
@export var allowed_list : Dictionary[StringName,bool]:
	set(value):
		if value:
			allowed_list = value
			notify_property_list_changed()

func _get_property_list() -> Array[Dictionary]:
	if behavior_agent:
		var list: Array[Dictionary] = behavior_agent.get_overridable_property_list()
		var ret: Array[Dictionary]
		for item in list:
			if allowed_list.get_or_add(item["name"],false):
				ret.append(item)
			
		return ret
	return []

func _get(property: StringName) -> Variant:
	if behavior_agent:
		return behavior_agent.bb_props[property] if behavior_agent.bb_props.has(property) else null
	return null

func _set(property: StringName, value: Variant) -> bool:
	if behavior_agent:
		if !behavior_agent.bb_props.has(property): return false
		if value is NodePath:
			value = behavior_agent.get_path_to(get_node(value))
		behavior_agent.bb_props[property]=value
		return true
	return false

func _ready() -> void:
	_prev_safe_pos = global_position
	queue_redraw()
	

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
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
