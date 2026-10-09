@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Follow Path"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"PathFollow") var path_follow : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 100.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var loop : bool = false

var _follow_ref : Node

func on_start() -> void:
	_follow_ref = _resolve_node(eval(&"path_follow"))
	if _follow_ref == null or not ("progress" in _follow_ref):
		abort("couldn't resolve PathFollow node")

func tick(delta: float) -> Status:
	_follow_ref.progress += (eval(&"speed") as float) * delta
	if _follow_ref.progress_ratio >= 1.0:
		if eval(&"loop"):
			_follow_ref.progress_ratio = fmod(_follow_ref.progress_ratio, 1.0)
			return Status.RUNNING
		_follow_ref.progress_ratio = 1.0
		return tick_next(delta)
		
	return Status.RUNNING

func set_instruction() -> String: return "Move {path_follow} along its path at speed {speed}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
