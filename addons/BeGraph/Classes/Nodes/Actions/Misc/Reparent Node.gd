@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Reparent Node"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var new_parent : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	var p_node := _resolve_node(eval(&"new_parent"))
	
	if target == null or p_node == null:
		return abort("couldn't resolve node or new parent")
		
	target.reparent(p_node)
	return tick_next(delta)

func set_instruction() -> String: return "Reparent {node} to {new_parent}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
