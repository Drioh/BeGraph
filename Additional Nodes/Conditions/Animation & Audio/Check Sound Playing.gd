@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Sound Playing"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether an audio player node is currently playing audio."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AudioStreamPlayer,AudioStreamPlayer2D,AudioStreamPlayer3D") var node : NodePath = NodePath("")

var _target : Node = null

func on_start() -> void:
	_target = eval(&"node", true)

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = eval(&"node", true)

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target) or not (_target is AudioStreamPlayer or _target is AudioStreamPlayer2D or _target is AudioStreamPlayer3D):
		return abort("couldn't resolve audio player")
		
	return tick_condition(delta, 0 if _target.playing else 1)

func on_end(_status: Status) -> void:
	_target = null

func set_instruction() -> String: return "Check if {node} is playing"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Playing", "Not playing"])
