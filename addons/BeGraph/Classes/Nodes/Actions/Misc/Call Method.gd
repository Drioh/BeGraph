@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Call Method"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Calls {method} on {node}, passing {args} as its arguments.\n\nSucceeds once called; fails if {node} can't be resolved or doesn't have that method."

func set_instruction() -> String:
	return "Call {method} on {node} with {args}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	var method : StringName = get("method")
	if not target.has_method(method):
		push_error("\"%s\": \"%s\" has no method \"%s\"" % [resource_name, target, method])
		return Status.FAILURE

	target.callv(method, get("args"))
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("method", &"")
	_add_behavior_property("args", [])
