@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Animator"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Plays an animation on an AnimationPlayer node and waits for it to finish."

@export_custom(BG.HINT_NONE, BG.PROPERTY+"AnimationPlayer") var animator : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var animation : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 1.0

var _animator_ref : AnimationPlayer

func on_start() -> void:
	_animator_ref = eval(&"animator", true) as AnimationPlayer
	if _animator_ref == null:
		abort("couldn't resolve AnimationPlayer")
		return
		
	_animator_ref.play(eval(&"animation"), -1, eval(&"speed") as float)

func tick(_delta: float) -> Status:
	if _animator_ref == null or not is_instance_valid(_animator_ref):
		return Status.FAILURE
	if _animator_ref.is_playing():
		return Status.RUNNING
	return Status.SUCCESS

func on_end(_status: Status) -> void:
	_animator_ref = null

func set_instruction() -> String: return "Play {animation} on {animator} at speed {speed}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
