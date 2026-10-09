@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Free All Children"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null:
		return abort("couldn't resolve target node")
		
	for child in target.get_children():
		child.queue_free()
		
	return tick_next(delta)

func set_instruction() -> String: return "Free all children of {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
