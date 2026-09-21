@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Destroy Node"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Queues {node} for deletion via queue_free().\n\nSucceeds as soon as deletion is requested andfails if {node} cannot be resolved."

func set_instruction() -> String:
	return "Destroy {node}"

func tick() -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" cannot resolve node to destroy" % resource_name)
		return Status.FAILURE
	target.queue_free()
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
