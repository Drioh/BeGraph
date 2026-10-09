@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Arrive"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var target : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 150.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var slowing_radius : float = 150.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var min_speed : float = 10.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var stop_distance : float = 2.0

var _node_ref : Node

func on_start() -> void:
	_node_ref = _resolve_node(eval(&"node"))
	if _node_ref == null:
		abort("couldn't resolve node to move")

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_node_ref = _resolve_node(eval(&"node"))

func tick(delta: float) -> Status:
	if _node_ref == null or not is_instance_valid(_node_ref):
		return abort("couldn't resolve node to move")
		
	var dest_pos = _resolve_position(eval(&"target"))
	if dest_pos == null:
		return abort("couldn't resolve target position")
		
	var distance : float = _get_position(_node_ref).distance_to(dest_pos)
	if distance <= maxf(eval(&"stop_distance") as float, 0.001):
		return tick_next(delta)
		
	var spd : float = eval(&"speed") as float
	var slowing : float = eval(&"slowing_radius") as float
	var desired : float = spd
	
	if slowing > 0.0 and distance < slowing:
		desired = maxf(spd * distance / slowing, minf(eval(&"min_speed") as float, spd))
		
	_step_towards(_node_ref, dest_pos, desired * delta)
	return Status.RUNNING

func _resolve_position(value: Variant) -> Variant:
	if value is Vector3: return value
	if value is Vector2: return Vector3(value.x, value.y, 0.0)
	var n : Node = _resolve_node(value)
	return _get_position(n) if n != null else null

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D: n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D: n.global_position = pos

func _step_towards(n: Node, destination: Vector3, max_step: float) -> float:
	var current : Vector3 = _get_position(n)
	var remaining : float = current.distance_to(destination)
	if remaining <= max_step or remaining <= 0.0001:
		_set_position(n, destination)
		return 0.0
	_set_position(n, current.move_toward(destination, max_step))
	return remaining - max_step

func set_instruction() -> String: return "Arrive at {target} with {node} (speed {speed}, slowing radius {slowing_radius})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
