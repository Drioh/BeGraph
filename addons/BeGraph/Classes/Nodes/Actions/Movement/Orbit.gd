@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Orbit"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Direction { CLOCKWISE, COUNTERCLOCKWISE }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var center : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var radius : float = 150.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var angular_speed : float = 90.0
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Clockwise,Counterclockwise") var direction : Direction = Direction.CLOCKWISE
@export_custom(BG.HINT_NONE, BG.PROPERTY) var radius_speed : float = 300.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 0.0

var _node_ref : Node
var _elapsed : float = 0.0

func on_start() -> void:
	_elapsed = 0.0
	_node_ref = _resolve_node(eval(&"node"))
	if _node_ref == null:
		abort("couldn't resolve node to orbit")

func tick(delta: float) -> Status:
	var center_pos = _resolve_position(eval(&"center"))
	if center_pos == null:
		return abort("couldn't resolve center position")
		
	var is_3d : bool = _node_ref is Node3D
	var offset : Vector3 = _get_position(_node_ref) - center_pos
	if offset.length() < 0.001:
		offset = Vector3.RIGHT
		
	var new_length : float = move_toward(offset.length(), eval(&"radius") as float, (eval(&"radius_speed") as float) * delta)
	offset = offset.normalized() * new_length
	
	var turn : float = 1.0 if (eval(&"direction") as Direction) == Direction.CLOCKWISE else -1.0
	if is_3d: turn = -turn
	
	var axis : Vector3 = Vector3.UP if is_3d else Vector3.BACK
	offset = offset.rotated(axis, deg_to_rad(eval(&"angular_speed") as float) * turn * delta)
	_set_position(_node_ref, center_pos + offset)
	
	var dur : float = eval(&"duration") as float
	if dur > 0.0:
		_elapsed += delta
		if _elapsed >= dur:
			return tick_next(delta)
			
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

func set_instruction() -> String: return "Orbit {node} around {center} (radius {radius}, {angular_speed} deg/s)"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
