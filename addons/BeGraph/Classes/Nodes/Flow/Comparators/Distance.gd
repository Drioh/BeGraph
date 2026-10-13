@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Distance"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Measures distance between node_a and node_b vs threshold."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node_a : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var node_b : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var threshold : float = 0.0

var _node_a : Node = null
var _node_b : Node = null

func on_start() -> void:
	_node_a = eval(&"node_a", true)
	_node_b = eval(&"node_b", true)

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node_a"):
		_node_a = eval(&"node_a", true)
	if key == get_blackboard_key(&"node_b"):
		_node_b = eval(&"node_b", true)

func tick(delta: float) -> Status:
	if _node_a == null or _node_b == null or not is_instance_valid(_node_a) or not is_instance_valid(_node_b):
		return abort("couldn't resolve target nodes")
		
	var dist : float = _get_position(_node_a).distance_to(_get_position(_node_b))
	var th : float = eval(&"threshold") as float
	
	if dist > th:
		return tick_condition(delta, 0)
	elif dist == th:
		return tick_condition(delta, 1)
	else:
		return tick_condition(delta, 2)

func on_end(_status: Status) -> void:
	_node_a = null
	_node_b = null

func _get_position(n : Node) -> Vector3:
	if n is Node2D:
		return Vector3(n.global_position.x, n.global_position.y, 0)
	if n is Node3D:
		return n.global_position
	return Vector3.ZERO

func set_instruction() -> String: return "Distance {node_a} - {node_b} vs {threshold}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray:
	return PackedStringArray(["distance > {threshold}", "distance = {threshold}", "distance < {threshold}"])
