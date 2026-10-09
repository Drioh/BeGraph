@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Chance"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var probability : float = 50.0

func tick(delta: float) -> Status:
	if randf() * 100.0 <= (eval(&"probability") as float):
		tick_condition(delta, 0)
	else:
		tick_condition(delta, 1)
	return Status.RUNNING

func set_instruction() -> String: return "Chance {probability}%"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Success ({probability}%)", "Failure"])
