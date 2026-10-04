@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Process Mode"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets the process_mode of {node} to {mode} (Inherit, Pausable, When Paused, Always, Disabled). Handy to e.g. disable a whole subtree or keep a menu running while the game is paused.\n\nSucceeds once applied; fails if {node} can't be resolved."

func set_instruction() -> String:
	return "Set {node}'s process mode: {mode}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	target.process_mode = int(get("mode")) as Node.ProcessMode
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Inherit,Pausable,When Paused,Always,Disabled")
