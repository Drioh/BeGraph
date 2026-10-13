@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Duplicate Node"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Duplicates a node and adds it to parent or as a sibling, optionally storing the duplicate in a blackboard variable."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var parent : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var return_blackboard_key : StringName = &""

func tick(_delta: float) -> Status:
	var source := eval(&"node", true)
	if source == null:
		return abort("couldn't resolve source node")
		
	var parent_node : Node = eval(&"parent", true)
	if parent_node == null:
		parent_node = source.get_parent()
		
	if parent_node == null:
		return abort("couldn't resolve parent node for duplicate")
		
	var dup : Node = source.duplicate()
	parent_node.add_child(dup)
	
	var ret_key : StringName = eval(&"return_blackboard_key")
	if ret_key != &"":
		var graph := get_graph()
		if graph != null:
			graph.set_blackboard_value(ret_key, dup)
			
	return Status.SUCCESS

func set_instruction() -> String: return "Duplicate {node} into {parent}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
