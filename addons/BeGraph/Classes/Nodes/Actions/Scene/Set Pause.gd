@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Pause"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Pauses the game, resumes it, or toggles the pause, depending on {mode}.\n\nA paused tree also stops the Behavior Agent running this graph, unless the agent's process_mode is set to 'Always' (needed to ever be able to resume from a graph).\n\nSucceeds once applied; fails only if the owning Behavior Agent can't be found."

enum Mode { ON, OFF, TOGGLE }

func set_instruction() -> String:
	return "Pause: {mode}"

func tick(delta:float) -> Status:
	var agent : Node = get_agent()
	if agent == null:
		return Status.FAILURE

	var tree : SceneTree = agent.get_tree()
	match get("mode"):
		Mode.ON:
			tree.paused = true
		Mode.OFF:
			tree.paused = false
		Mode.TOGGLE:
			tree.paused = not tree.paused

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "On,Off,Toggle")
