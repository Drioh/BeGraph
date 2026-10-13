@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Emit Signal"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Emits the 'behavior_signal' on the owning BehaviorAgent with the given arguments."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var args : Array = []

func tick(_delta: float) -> Status:
	var agent := get_agent()
	if agent == null or (not agent.has_user_signal("behavior_signal") and not "behavior_signal" in agent):
		return abort("owning BehaviorAgent not found or signal missing")
		
	agent.emit_signal("behavior_signal", eval(&"args"))
	return Status.SUCCESS

func set_instruction() -> String: return "Emit agent signal with {args}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
