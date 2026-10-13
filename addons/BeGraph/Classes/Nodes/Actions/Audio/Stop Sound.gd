@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Stop Sound"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Stops playback on an audio player node."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AudioStreamPlayer,AudioStreamPlayer2D,AudioStreamPlayer3D") var node : NodePath = NodePath("")

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null or not (target is AudioStreamPlayer or target is AudioStreamPlayer2D or target is AudioStreamPlayer3D):
		return abort("couldn't resolve an audio player")
		
	target.stop()
	return Status.SUCCESS

func set_instruction() -> String: return "Stop sound on {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
