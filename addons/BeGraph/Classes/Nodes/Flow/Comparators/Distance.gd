@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Distance"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Measures distance between node_a and node_b vs threshold."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node_a : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var node_b : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var threshold : float = 0.0

func tick(delta: float) -> Status:
	var a : Node = _resolve_node(eval(&"node_a"))
	var b : Node = _resolve_node(eval(&"node_b"))
	
	if a == null or b == null:
		return abort("couldn't resolve target nodes")
		
	var dist : float = _get_position(a).distance_to(_get_position(b))
	var th : float = eval(&"threshold") as float
	
	if dist > th:
		tick_condition(delta, 0)
	elif dist == th:
		tick_condition(delta, 1)
	else:
		tick_condition(delta, 2)
		
	return Status.RUNNING

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
