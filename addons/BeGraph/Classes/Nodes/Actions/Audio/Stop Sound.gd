@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Stop Sound"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Stops {node} (an AudioStreamPlayer/2D/3D) if it's currently playing.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't an audio player."

func set_instruction() -> String:
	return "Stop sound on {node}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_audio_player(target):
		push_error("\"%s\" couldn't resolve an audio player" % resource_name)
		return Status.FAILURE

	target.stop()
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "AudioStreamPlayer,AudioStreamPlayer2D,AudioStreamPlayer3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)

## Returns [code]true[/code] if [param n] is an audio player this node supports.
func _is_audio_player(n: Node) -> bool:
	return n is AudioStreamPlayer or n is AudioStreamPlayer2D or n is AudioStreamPlayer3D
