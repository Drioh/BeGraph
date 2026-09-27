@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Free All Children"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Queues every direct child of {node} for deletion via queue_free().\n\nSucceeds once applied; fails if {node} can't be resolved."

func set_instruction() -> String:
	return "Free all children of {node}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	for child in target.get_children():
		child.queue_free()

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
