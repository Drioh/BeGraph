@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Value Comparator"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var value_1 : int = 0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var value_2 : int = 0

func tick(delta: float) -> Status:
	var v1 = eval(&"value_1")
	var v2 = eval(&"value_2")
	
	if v1 > v2:
		tick_condition(delta, 0)
	elif v1 == v2:
		tick_condition(delta, 1)
	else:
		tick_condition(delta, 2)
		
	return Status.RUNNING

func set_instruction() -> String: return "Compare {value_1} and {value_2}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["{value_1} > {value_2}", "{value_1} = {value_2}", "{value_1} < {value_2}"])
