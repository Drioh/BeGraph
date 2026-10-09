@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Animator"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"AnimationPlayer") var animator : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var animation : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 1.0

var _animator_ref : AnimationPlayer

func on_start() -> void:
	_animator_ref = _resolve_node(eval(&"animator")) as AnimationPlayer
	if _animator_ref == null:
		abort("couldn't resolve AnimationPlayer")
		return
		
	_animator_ref.play(eval(&"animation"), -1, eval(&"speed") as float)

func tick(delta: float) -> Status:
	if _animator_ref.is_playing():
		return Status.RUNNING
	return tick_next(delta)

func set_instruction() -> String: return "Play {animation} on {animator} at speed {speed}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
