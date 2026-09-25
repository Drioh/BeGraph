@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Value"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Writes a random value between {min} and {max} into the blackboard entry named {variable_name}, as an int or a float depending on {mode}.\n\nSucceeds unless {variable_name} isn't found in the graph's blackboard, in which case it fails."

enum Mode { INT, FLOAT }

func set_instruction() -> String:
	return "Set {variable_name} = random {mode} in [{min}, {max}]"

func tick(delta:float) -> Status:
	var graph : BehaviorGraph = _graph_ref.get_ref()
	if graph == null:
		return Status.FAILURE

	var variable : BlackboardVariable = graph.get_blackboard_property(get("variable_name"))
	if variable == null:
		push_error("\"%s\" couldn't find variable \"%s\" in blackboard" % [resource_name, get("variable_name")])
		return Status.FAILURE

	var min_value : float = get("min")
	var max_value : float = get("max")
	variable.value = randi_range(int(min_value), int(max_value)) if get("mode") == Mode.INT else randf_range(min_value, max_value)

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("variable_name", &"")
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Int,Float")
	_add_behavior_property("min", float(0.0))
	_add_behavior_property("max", float(1.0))
