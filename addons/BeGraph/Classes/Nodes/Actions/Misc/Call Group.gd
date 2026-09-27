@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Call Group"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Calls {method} (with {args} as arguments) on every node currently in the group named {group}.\n\nSucceeds once applied; fails only if the owning Behavior Agent can't be found."

func set_instruction() -> String:
	return "Call {method} on group {group} with {args}"

func tick(delta:float) -> Status:
	var agent : Node = get_agent()
	if agent == null:
		return Status.FAILURE

	var method : StringName = get("method")
	var args : Array = get("args")
	for n in agent.get_tree().get_nodes_in_group(get("group")):
		if n.has_method(method):
			n.callv(method, args)

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("group", &"")
	_add_behavior_property("method", &"")
	_add_behavior_property("args", [])
