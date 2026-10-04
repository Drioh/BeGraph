@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Velocity"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Compares the speed of {node} (a CharacterBody2D/3D using velocity, or a RigidBody2D/3D using linear_velocity) with {threshold}, branching to 'speed > threshold' or 'speed <= threshold'.\n\n{axis} selects what is measured: the full velocity (Total), only the horizontal part (X in 2D, X/Z in 3D) or only the vertical part (Y). Horizontal and Vertical are absolute values.\n\nFails if {node} can't be resolved or isn't a supported body."

enum Axis { TOTAL, HORIZONTAL, VERTICAL }

func set_instruction() -> String:
	return "Check {node}'s {axis} speed vs {threshold}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	var speed : float = _speed_of(target) if target != null else -1.0
	if speed < 0.0:
		push_error("\"%s\" couldn't resolve a character/rigid body" % resource_name)
		return Status.FAILURE

	if speed > get("threshold"):
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

## Returns the measured speed, or -1 if [param n] isn't supported.
func _speed_of(n : Node) -> float:
	var v : Variant
	if n is CharacterBody2D or n is CharacterBody3D:
		v = n.velocity
	elif n is RigidBody2D or n is RigidBody3D:
		v = n.linear_velocity
	else:
		return -1.0

	match get("axis"):
		Axis.HORIZONTAL:
			if v is Vector2:
				return absf(v.x)
			return Vector2(v.x, v.z).length()
		Axis.VERTICAL:
			return absf(v.y)
	return v.length()

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("axis", 0, PROPERTY_HINT_ENUM, "Total,Horizontal,Vertical")
	_add_behavior_property("threshold", float(10.0))

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"speed > {threshold}",
		"speed <= {threshold}"
	])
