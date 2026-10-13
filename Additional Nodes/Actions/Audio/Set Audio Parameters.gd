@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Audio Parameters"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets volume_db and pitch_scale on an audio player node."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AudioStreamPlayer,AudioStreamPlayer2D,AudioStreamPlayer3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var volume_db : float = 0.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var pitch_scale : float = 1.0

func tick(_delta: float) -> Status:
	var target :Node= eval(&"node", true)
	if target == null or not (target is AudioStreamPlayer or target is AudioStreamPlayer2D or target is AudioStreamPlayer3D):
		return abort("couldn't resolve an audio player")
		
	target.volume_db = eval(&"volume_db") as float
	target.pitch_scale = eval(&"pitch_scale") as float
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s volume to {volume_db}db, pitch to {pitch_scale}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
