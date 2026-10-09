@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Condition"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Ticks its successor only if {condition} is true."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var condition : bool = false

func tick(delta: float) -> Status:
	if bool(eval(&"condition")) and _next_ref.size() > 0:
		return tick_next(delta)
	return Status.FAILURE

func set_instruction() -> String: return "If {condition}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
