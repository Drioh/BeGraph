@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Timer Running"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (a Timer) is currently running, branching to 'Running' or 'Stopped'.\n\nUnlike 'Timer Wait', it doesn't start the timer nor block: it only reads its state.\n\nFails if {node} can't be resolved or isn't a Timer."

func set_instruction() -> String:
	return "Check if timer {node} is running"

func tick(delta:float) -> Status:
	var target : Timer = _resolve_node(get("node")) as Timer
	if target == null:
		push_error("\"%s\" couldn't resolve Timer" % resource_name)
		return Status.FAILURE

	if not target.is_stopped():
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Timer", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Running",
		"Stopped"
	])
