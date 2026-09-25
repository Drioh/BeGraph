@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Add To Group"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Adds {node} to the group named {group}.\n\nSucceeds once applied; fails if {node} can't be resolved."

func set_instruction() -> String:
	return "Add {node} to group {group}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	target.add_to_group(get("group"))
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("group", &"")
