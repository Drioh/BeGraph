@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Quit Game"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Quits the game with the exit code {exit_code} (0 = normal exit).\n\nThe node has no successor. Fails only if the owning Behavior Agent can't be found."

func set_instruction() -> String:
	return "Quit game (exit code {exit_code})"

func tick(delta:float) -> Status:
	var agent : Node = get_agent()
	if agent == null:
		return Status.FAILURE

	agent.get_tree().quit(get("exit_code"))
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("exit_code", int(0))
