@tool
class_name EnumSelectorNode
extends BehaviorNode

const DISPLAY_NAME : String = "Enum Selector"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Branches to one of several conditions based on {value}, an index into the editable {enum_values} (PackedStringArray) list.\n\nTicks the successor linked to the matching condition; fails if {value} is out of range.\n\nBranches get updated in real time"

@export_custom(BG.HINT_NONE,BG.CONDITION) var enum_values :PackedStringArray = []
@export_custom(BG.HINT_ENUM,BG.ENUMERATOR + "enum_values") var value : int = 0

func tick(delta:float) -> Status:
	var idx : int = eval(&"value") as int
	if idx < 0 or idx >= conditions.size():
		return Status.FAILURE
	return tick_condition(delta, idx)

func set_instruction() -> String:return "Enum Selector: {value}"
func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false
