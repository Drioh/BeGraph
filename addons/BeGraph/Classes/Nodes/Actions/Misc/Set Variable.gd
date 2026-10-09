@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Variable"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Writes {value} into the blackboard entry named {variable_name}."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var variable_name : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var value : Variant = null

func tick(delta: float) -> Status:
	var key : StringName = eval(&"variable_name") as StringName
	var graph := get_graph()
	if graph == null:
		return abort("graph reference lost")
		
	var variable := graph.get_blackboard_property(key)
	if variable == null:
		return abort("variable '%s' not found in blackboard" % key)
		
	variable.value = eval(&"value")
	return tick_next(delta)

func set_instruction() -> String: return "Set {variable_name} = {value}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
