@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Quit Game"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var exit_code : int = 0

func tick(delta: float) -> Status:
	var agent := get_agent()
	if agent == null:
		return abort("owning behavior agent not found")
		
	agent.get_tree().quit(eval(&"exit_code") as int)
	return Status.SUCCESS

func set_instruction() -> String: return "Quit game (exit code {exit_code})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
