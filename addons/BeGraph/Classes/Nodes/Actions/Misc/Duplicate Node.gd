@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Duplicate Node"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var parent : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var variable_name : StringName = &""

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	var parent_node := _resolve_node(eval(&"parent"))
	
	if target == null or parent_node == null:
		return abort("couldn't resolve node or parent")
		
	var graph := get_graph()
	if graph == null:
		return abort("lost graph reference")
		
	var key : StringName = eval(&"variable_name") as StringName
	var variable := graph.get_blackboard_property(key)
	if variable == null:
		return abort("blackboard variable '%s' not found" % key)
		
	var copy : Node = target.duplicate()
	parent_node.add_child(copy)
	variable.value = copy
	return tick_next(delta)

func set_instruction() -> String: return "Duplicate {node} under {parent} into {variable_name}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
