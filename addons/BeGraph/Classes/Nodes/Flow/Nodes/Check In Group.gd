@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check In Group"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} belongs to the group named {group}, branching to 'In group' or 'Not in group'.\n\nFails if {node} can't be resolved."

func set_instruction() -> String:
	return "Check if {node} is in group {group}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	if target.is_in_group(get("group")):
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("group", &"")

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"In group",
		"Not in group"
	])
