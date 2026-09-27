@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Reparent Node"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Moves {node} to become a child of {new_parent}, keeping its global transform, via reparent().\n\nSucceeds once applied; fails if {node} or {new_parent} can't be resolved."

func set_instruction() -> String:
	return "Reparent {node} to {new_parent}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	var new_parent : Node = _resolve_node(get("new_parent"))
	if target == null or new_parent == null:
		push_error("\"%s\" couldn't resolve node or new parent" % resource_name)
		return Status.FAILURE

	target.reparent(new_parent)
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("new_parent", NodePath(""))
