@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Pause"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Pauses, unpauses, or toggles the paused state of the SceneTree."

enum Mode { ON, OFF, TOGGLE }

@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+ "On,Off,Toggle") var mode : Mode = Mode.ON

func tick(_delta: float) -> Status:
	var agent : Node = get_agent()
	if agent == null:
		return abort("owning behavior agent not found")
		
	var tree : SceneTree = agent.get_tree()
	match eval(&"mode") as Mode:
		Mode.ON: tree.paused = true
		Mode.OFF: tree.paused = false
		Mode.TOGGLE: tree.paused = not tree.paused
		
	return Status.SUCCESS

func set_instruction() -> String: return "Pause: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
