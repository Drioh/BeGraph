@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Play Sound"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Plays {player} (AudioStreamPlayer) at the given {volume_db} and {pitch_scale}.\n\nReturns RUNNING while playing and SUCCESS once playback ends; fails if {player} cannot be resolved."

@export_custom(PROPERTY_HINT_NODE_PATH_VALID_TYPES, BG.PROPERTY + "AudioStreamPlayer") var player : NodePath = ^""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var volume_db : float = 0.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var pitch_scale : float = 1.0

var _audio_player : AudioStreamPlayer

func on_start() -> void:
	_audio_player = eval(&"player", true) as AudioStreamPlayer
	if _audio_player == null:
		abort("couldn't resolve AudioStreamPlayer")
		return

	_audio_player.volume_db = eval(&"volume_db") as float
	_audio_player.pitch_scale = eval(&"pitch_scale") as float
	_audio_player.play()

func tick(_delta: float) -> Status:
	if _audio_player == null or not is_instance_valid(_audio_player):
		return Status.FAILURE
	if _audio_player.playing:
		return Status.RUNNING
	return Status.SUCCESS

func on_end(status: Status) -> void:
	if status != Status.SUCCESS and _audio_player != null and is_instance_valid(_audio_player) and _audio_player.playing:
		_audio_player.stop()
	_audio_player = null

func set_instruction() -> String: return "Play sound on {player} (vol {volume_db} db, pitch {pitch_scale})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
