@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Call Method"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var method : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var args : Array = []

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null:
		return abort("couldn't resolve target node")
		
	var m_name : StringName = eval(&"method") as StringName
	if not target.has_method(m_name):
		return abort("target node has no method '%s'" % m_name)
		
	target.callv(m_name, eval(&"args") as Array)
	return tick_next(delta)

func set_instruction() -> String: return "Call {method} on {node} with {args}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
