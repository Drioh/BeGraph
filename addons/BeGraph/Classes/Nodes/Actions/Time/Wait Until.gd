@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait Until"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var condition : bool = false
@export_custom(BG.HINT_NONE, BG.PROPERTY) var timeout : float = 0.0

var _elapsed : float = 0.0

func on_start() -> void:
	_elapsed = 0.0

func tick(delta: float) -> Status:
	if bool(eval(&"condition")):
		_elapsed = 0.0
		return tick_next(delta)
		
	var tout : float = eval(&"timeout") as float
	if tout > 0.0:
		_elapsed += delta
		if _elapsed >= tout:
			_elapsed = 0.0
			return Status.FAILURE
			
	return Status.RUNNING

func set_instruction() -> String: return "Wait until {condition} (timeout: {timeout}s)"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
