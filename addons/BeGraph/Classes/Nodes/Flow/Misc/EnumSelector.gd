@tool
class_name EnumSelectorNode
extends BehaviorNode

const DISPLAY_NAME : String = "Enum Selector"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Branches to one of several conditions based on {value}, an index into the editable {enum_values} (PackedStringArray) list.\n\nTicks the successor linked to the matching condition; fails if {value} is out of range.\n\nBranches get updated in real time"

func set_instruction() -> String:
	return "Enum Selector: {value}"

func tick(delta:float) -> Status:
	var value : int = get("value")
	if value < 0 or value >= conditions.size():
		return Status.FAILURE
	return tick_condition(delta,value)

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	## Editabile dall'Inspector (pulsante matita sul titlebar del nodo):
	## aggiungi, rimuovi, rinomina o riordina le voci liberamente.
	_add_behavior_property("enum_values", PackedStringArray([]),PROPERTY_HINT_NONE,"","conditions")
	_add_behavior_property("value", 0, PROPERTY_HINT_ENUM,"","enum_values")
