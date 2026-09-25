@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Remove From Group"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Removes {node} from the group named {group}.\n\nSucceeds once applied; fails if {node} can't be resolved."

func set_instruction() -> String:
	return "Remove {node} from group {group}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	target.remove_from_group(get("group"))
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("group", &"")
