@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Rigid Body Frozen"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (a RigidBody2D/3D) is currently frozen, branching to 'Frozen' or 'Not frozen'.\n\nFails if {node} can't be resolved or isn't a rigid body."

func set_instruction() -> String:
	return "Check {node}'s freeze state"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_rigid_body(target):
		push_error("\"%s\" couldn't resolve a rigid body" % resource_name)
		return Status.FAILURE

	if target.freeze:
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "RigidBody2D,RigidBody3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Frozen",
		"Not frozen"
	])

## Returns [code]true[/code] if [param n] is a rigid body this node supports.
func _is_rigid_body(n: Node) -> bool:
	return n is RigidBody2D or n is RigidBody3D
