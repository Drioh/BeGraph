@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Play Sound"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

var _started : bool = false

func set_instruction() -> String:
	return "Play sound on {player} (vol {volume_db} db, pitch {pitch_scale})"

func tick() -> Status:
	var player : Node = _resolve_node(get("player"))
	if player == null:
		push_error("\"%s\" couldn't resolve AudioStreamPlayer" % resource_name)
		return Status.FAILURE

	if not _started:
		player.volume_db = get("volume_db")
		player.pitch_scale = get("pitch_scale")
		player.play()
		_started = true
		return Status.RUNNING

	if player.is_playing():
		return Status.RUNNING

	_started = false
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("player", NodePath(""))
	_add_behavior_property("volume_db", float(0.0))
	_add_behavior_property("pitch_scale", float(1.0))
