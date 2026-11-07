@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits {seconds}s plus a random offset."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var seconds : float = 1.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var random_minimum : float = 0.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var random_maximum : float = 0.0

var _elapsed : float = 0.0
var _target : float = 0.0

func on_start() -> void:
	_elapsed = 0.0
	_target = (eval(&"seconds") as float) + randf_range(eval(&"random_minimum") as float, eval(&"random_maximum") as float)

func tick(delta: float) -> Status:
	_elapsed += delta
	if _elapsed >= _target:
		return Status.SUCCESS
	return Status.RUNNING

func on_end(_status: Status) -> void:
	_elapsed = 0.0

func set_instruction() -> String: return "Wait {seconds}s"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
