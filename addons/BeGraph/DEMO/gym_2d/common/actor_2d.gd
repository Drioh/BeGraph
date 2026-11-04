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
@export var allowed_list : Dictionary[StringName,bool]:
	set(value):
		if value:
			allowed_list = value
			notify_property_list_changed()

func _get_property_list() -> Array[Dictionary]:
	if behavior_agent == null: return []
	
	var list: Array[Dictionary] = behavior_agent.get_overridable_property_list()
	var ret: Array[Dictionary]
	for item in list:
		if !allowed_list.get_or_add(item["name"],false): continue #both sets the dictionary and checks if the associated value to item["name"] is true or false
		ret.append(item)
	return ret

func _get(property: StringName) -> Variant:
	if behavior_agent == null: return null
	var key : StringName = property if property.begins_with(BG.OBP) else BG.OBP+"/"+property
	return behavior_agent.bb_props.get(key) #returns either the value or null, if the key "property" does not exist in bb_props

func _set(property: StringName, value: Variant) -> bool:
	if behavior_agent == null : return false
	
	var key : StringName = property if property.begins_with(BG.OBP) else BG.OBP+"/"+property
	print(key)
	if !behavior_agent.bb_props.has(key): return false
	if value is NodePath:
		value = behavior_agent.get_path_to(get_node(value)) #getting a path relative to the agent, for node resolution purposes
	behavior_agent.bb_props[key]=value
	return true
#endregion

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
