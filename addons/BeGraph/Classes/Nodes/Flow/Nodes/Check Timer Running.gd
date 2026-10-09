@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Timer Running"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Timer") var node : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node")) as Timer
	if target == null:
		return abort("couldn't resolve Timer")
		
	tick_condition(delta, 0 if not target.is_stopped() else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check if timer {node} is running"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Running", "Stopped"])
