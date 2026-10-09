@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Field Of View"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

enum Forward { POS_X, NEG_X, POS_Y, NEG_Y, POS_Z, NEG_Z }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Node2D,Node3D") var target : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var angle : float = 90.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var max_distance : float = 0.0
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"+X (2D right),-X (2D left),+Y (2D down),-Y (2D up),+Z (3D back),-Z (3D forward)") var forward : Forward = Forward.POS_X

var _node_ref : Node

func on_start() -> void:
	_node_ref = _resolve_node(eval(&"node"))
	if _node_ref == null:
		abort("couldn't resolve source node")

func tick(delta: float) -> Status:
	var target_node : Node = _resolve_node(eval(&"target"))
	if target_node == null:
		return abort("couldn't resolve target node")
		
	var to_target : Vector3 = _get_position(target_node) - _get_position(_node_ref)
	var distance : float = to_target.length()
	var max_dist : float = eval(&"max_distance") as float
	var in_view : bool = true
	
	if max_dist > 0.0 and distance > max_dist:
		in_view = false
	elif distance > 0.0:
		var half_angle : float = deg_to_rad(eval(&"angle") as float) * 0.5
		in_view = _forward_vector().angle_to(to_target) <= half_angle
		
	tick_condition(delta, 0 if in_view else 1)
	return Status.RUNNING

func _forward_vector() -> Vector3:
	var local : Vector3
	match eval(&"forward") as Forward:
		Forward.POS_X: local = Vector3.RIGHT
		Forward.NEG_X: local = Vector3.LEFT
		Forward.POS_Y: local = Vector3.UP
		Forward.NEG_Y: local = Vector3.DOWN
		Forward.POS_Z: local = Vector3.BACK
		_: local = Vector3.FORWARD
		
	if _node_ref is Node2D:
		var v : Vector2 = _node_ref.global_transform.basis_xform(Vector2(local.x, local.y))
		return Vector3(v.x, v.y, 0.0).normalized()
	if _node_ref is Node3D:
		return (_node_ref.global_transform.basis * local).normalized()
	return local

func _get_position(n: Node) -> Vector3:
	if n is Node2D: return Vector3(n.global_position.x, n.global_position.y, 0.0)
	if n is Node3D: return n.global_position
	return Vector3.ZERO

func set_instruction() -> String: return "Is {target} in {node}'s view ({angle} deg, max {max_distance})"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Target in view", "Target out of view"])
