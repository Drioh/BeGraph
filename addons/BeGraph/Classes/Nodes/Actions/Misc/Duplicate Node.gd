@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Duplicate Node"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Duplicates {node}, adds the copy as a child of {parent}, and writes it into the blackboard entry named {variable_name} so later nodes can reference it.\n\nSucceeds once applied; fails if {node}/{parent} can't be resolved or {variable_name} isn't found in the blackboard."

func set_instruction() -> String:
	return "Duplicate {node} under {parent} into {variable_name}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	var parent : Node = _resolve_node(get("parent"))
	if target == null or parent == null:
		push_error("\"%s\" couldn't resolve node or parent" % resource_name)
		return Status.FAILURE

	var graph : BehaviorGraph = _graph_ref.get_ref()
	if graph == null:
		return Status.FAILURE

	var variable : BlackboardVariable = graph.get_blackboard_property(get("variable_name"))
	if variable == null:
		push_error("\"%s\" couldn't find variable \"%s\" in blackboard" % [resource_name, get("variable_name")])
		return Status.FAILURE

	var copy : Node = target.duplicate()
	parent.add_child(copy)
	variable.value = copy

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("parent", NodePath(""))
	_add_behavior_property("variable_name", &"")
