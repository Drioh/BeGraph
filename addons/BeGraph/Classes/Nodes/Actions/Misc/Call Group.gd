@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Call Group"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var group : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var method : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var args : Array = []

func tick(delta: float) -> Status:
	var agent := get_agent()
	if agent == null:
		return abort("owning BehaviorAgent not found")
		
	var m_name : StringName = eval(&"method") as StringName
	var arguments : Array = eval(&"args") as Array
	
	for n in agent.get_tree().get_nodes_in_group(eval(&"group")):
		if n.has_method(m_name):
			n.callv(m_name, arguments)
			
	return tick_next(delta)

func set_instruction() -> String: return "Call {method} on group {group} with {args}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
