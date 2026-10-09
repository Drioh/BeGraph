@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Destroy Node"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Queues {node} for deletion via queue_free()."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target : Node = _resolve_node(eval(&"node"))
	if target == null:
		return abort("cannot resolve node to destroy")
		
	target.queue_free()
	return tick_next(delta)

func set_instruction() -> String: return "Destroy {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
