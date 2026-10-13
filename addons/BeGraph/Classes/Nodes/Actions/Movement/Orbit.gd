@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Orbit"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Orbits a node around a target center point or node at a specified radius and angular speed."

enum Axis3D { Y, X, Z }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var center : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var radius : float = 100.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var angular_speed : float = 90.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 0.0
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Y (yaw/horizontal),X (pitch),Z (roll)") var axis_3d : Axis3D = Axis3D.Y

var _node_ref : Node
var _center_ref : Node
var _angle : float = 0.0
var _elapsed : float = 0.0

func on_start() -> void:
	_elapsed = 0.0
	_node_ref = eval(&"node", true)
	if _node_ref == null:
		abort("couldn't resolve node to orbit")
		return
		
	var raw = eval(&"center")
	_center_ref = eval(&"center", true) if (raw is NodePath or raw is String) else null
	
	var c_pos = _resolve_center_pos()
	if c_pos != null:
		var diff : Vector3 = _get_position(_node_ref) - (c_pos as Vector3)
		if _node_ref is Node3D:
			match eval(&"axis_3d") as Axis3D:
				Axis3D.X: _angle = atan2(diff.z, diff.y)
				Axis3D.Z: _angle = atan2(diff.y, diff.x)
				_: _angle = atan2(diff.z, diff.x)
		else:
			_angle = atan2(diff.y, diff.x)

func tick(delta: float) -> Status:
	if _node_ref == null or not is_instance_valid(_node_ref):
		return abort("couldn't resolve node to orbit")
		
	var c_pos = _resolve_center_pos()
	if c_pos == null:
		return abort("couldn't resolve center position")
		
	var dur : float = eval(&"duration") as float
	if dur > 0.0:
		_elapsed += delta
		if _elapsed >= dur:
			return Status.SUCCESS
			
	_angle += deg_to_rad(eval(&"angular_speed") as float) * delta
	var rad : float = eval(&"radius") as float
	var offset : Vector3 = Vector3.ZERO
	
	if _node_ref is Node3D:
		match eval(&"axis_3d") as Axis3D:
			Axis3D.X: offset = Vector3(0.0, cos(_angle), sin(_angle)) * rad
			Axis3D.Z: offset = Vector3(cos(_angle), sin(_angle), 0.0) * rad
			_: offset = Vector3(cos(_angle), 0.0, sin(_angle)) * rad
	else:
		offset = Vector3(cos(_angle), sin(_angle), 0.0) * rad
		
	_set_position(_node_ref, (c_pos as Vector3) + offset)
	return Status.RUNNING

func on_end(_status: Status) -> void:
	_node_ref = null
	_center_ref = null
	_elapsed = 0.0

func _resolve_center_pos() -> Variant:
	if _center_ref != null and is_instance_valid(_center_ref):
		return _get_position(_center_ref)
	var raw = eval(&"center")
	if raw is Vector3: return raw
	if raw is Vector2: return Vector3(raw.x, raw.y, 0.0)
	var n : Node = eval(&"center", true)
	return _get_position(n) if n != null else null

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func _set_position(n: Node, pos: Vector3) -> void:
	if n is Node2D: n.global_position = Vector2(pos.x, pos.y)
	elif n is Node3D: n.global_position = pos

func set_instruction() -> String: return "Orbit {node} around {center} (radius: {radius})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
