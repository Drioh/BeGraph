@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Follow Path"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Advances a PathFollow2D or PathFollow3D node along its curve at the specified speed or duration."

enum Mode { SPEED, DURATION }

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"PathFollow2D,PathFollow3D") var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Speed,Duration") var mode : Mode = Mode.SPEED
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 100.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 2.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var loop : bool = false

var _path_follow : Node = null
var _elapsed : float = 0.0

func on_start() -> void:
	_elapsed = 0.0
	_path_follow = eval(&"node", true)
	if not (_path_follow is PathFollow2D or _path_follow is PathFollow3D):
		abort("couldn't resolve PathFollow node")
		return
		
	_path_follow.loop = eval(&"loop")

func tick(delta: float) -> Status:
	if _path_follow == null or not is_instance_valid(_path_follow):
		return Status.FAILURE
		
	var is_loop : bool = eval(&"loop") as bool
	_path_follow.loop = is_loop
	
	if (eval(&"mode") as Mode) == Mode.SPEED:
		_path_follow.progress += (eval(&"speed") as float) * delta
		if not is_loop and _path_follow.progress_ratio >= 1.0:
			return Status.SUCCESS
		return Status.RUNNING
		
	_elapsed += delta
	var dur : float = maxf(eval(&"duration") as float, 0.001)
	_path_follow.progress_ratio = clampf(_elapsed / dur, 0.0, 1.0)
	
	if _elapsed >= dur:
		if is_loop:
			_elapsed = 0.0
			return Status.RUNNING
		return Status.SUCCESS
		
	return Status.RUNNING

func on_end(_status: Status) -> void:
	_path_follow = null
	_elapsed = 0.0

func set_instruction() -> String: return "Follow path on {node} ({mode})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
