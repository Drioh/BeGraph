@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Sound Playing"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (an AudioStreamPlayer/2D/3D) is currently playing, branching to 'Playing' or 'Stopped'.\n\nFails if {node} can't be resolved or isn't an audio player."

func set_instruction() -> String:
	return "Check if {node} is playing"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_audio_player(target):
		push_error("\"%s\" couldn't resolve an audio player" % resource_name)
		return Status.FAILURE

	if target.playing:
		tick_condition(delta,0)
	else:
		tick_condition(delta,1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "AudioStreamPlayer,AudioStreamPlayer2D,AudioStreamPlayer3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Playing",
		"Stopped"
	])

## Returns [code]true[/code] if [param n] is an audio player this node supports.
func _is_audio_player(n: Node) -> bool:
	return n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D
