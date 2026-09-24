@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Distance"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Measures the distance between {node_a} and {node_b} and compares it to {threshold}, branching to the matching condition ('>', '=' or '<').\n\nFails if either node can't be resolved."

var a : Node
var b : Node

func set_instruction() -> String:
	return "Distance {node_a} - {node_b} vs {threshold}"

func tick(delta:float) -> Status:
	if dirty:
		a = _resolve_node(get("node_a"))
		if a == null:
			push_error("\"%s\" couldn't resolve first node" % resource_name)
			dirty=false
			return Status.FAILURE
		
		b = _resolve_node(get("node_b"))
		if b == null:
			push_error("\"%s\" couldn't resolve second node" % resource_name)
			dirty=false
			return Status.FAILURE
	dirty=false
	
	var distance : float = _get_position(a).distance_to(_get_position(b))
	var threshold : float = get("threshold")
	if distance > threshold:
		tick_condition(delta,0)
		return Status.RUNNING
	if distance == threshold:
		tick_condition(delta,1)
		return Status.RUNNING
	if distance < threshold:
		tick_condition(delta,2)
		return Status.RUNNING
	push_error("Something went wrong with resource %s"%resource_name)
	return Status.FAILURE
func set_node_category()->String:return "control_flow_node"
func set_input()->bool:return true
func set_output()->bool:return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node_a", NodePath(""))
	_add_behavior_property("node_b", NodePath(""))
	_add_behavior_property("threshold", float(0.0))

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"distance > {threshold}",
		"distance = {threshold}",
		"distance < {threshold}"
	])
	
func _get_position(n : Node) -> Vector3:
	if n is Node2D:
		var pos : Vector2 = n.global_position
		return Vector3(pos.x, pos.y, 0)
	if n is Node3D:
		return n.global_position
	return Vector3.ZERO
