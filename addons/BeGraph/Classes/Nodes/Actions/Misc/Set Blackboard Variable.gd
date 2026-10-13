@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Blackboard Variable"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Writes a value to a Blackboard variable by name."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var variable_name : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var value : Variant = null

func tick(_delta: float) -> Status:
	var graph := get_graph()
	if graph == null:
		return abort("lost graph reference")
		
	var var_name : StringName = eval(&"variable_name")
	if var_name == &"":
		return abort("no variable name set")
		
	graph.set_blackboard_value(var_name, eval(&"value"))
	return Status.SUCCESS

func set_instruction() -> String: return "Set BB var {variable_name} = {value}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
