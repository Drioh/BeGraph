@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Variable"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Writes {value} into the blackboard entry named {variable_name}, overwriting it.\n\nSucceeds unless {variable_name} isn't found in the graph's blackboard, in which case it fails."

func set_instruction() -> String:
	return "Set {variable_name} = {value}"

func tick(delta:float) -> Status:
	var graph : BehaviorGraph = _graph_ref.get_ref()
	if graph == null:
		return Status.FAILURE

	var variable : BlackboardVariable = graph.get_blackboard_property(get("variable_name"))
	if variable == null:
		push_error("\"%s\" couldn't find variable \"%s\" in blackboard" % [resource_name, get("variable_name")])
		return Status.FAILURE

	variable.value = get("value")
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("variable_name", &"")
	_add_behavior_property("value", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
