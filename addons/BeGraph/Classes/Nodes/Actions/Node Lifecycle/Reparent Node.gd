@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Reparent Node"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Reparents a node to a new parent, optionally keeping its global transform."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var new_parent : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var keep_global_transform : bool = true

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	var parent_node := eval(&"new_parent", true)
	
	if target == null or parent_node == null:
		return abort("couldn't resolve node or new parent")
		
	target.reparent(parent_node, eval(&"keep_global_transform") as bool)
	return Status.SUCCESS

func set_instruction() -> String: return "Reparent {node} to {new_parent}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
