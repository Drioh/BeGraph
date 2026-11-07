@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait Until"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits until a condition evaluates to true, with an optional timeout duration."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var condition : bool = false
@export_custom(BG.HINT_NONE, BG.PROPERTY) var timeout : float = 0.0

var _elapsed : float = 0.0

func on_start() -> void:
	_elapsed = 0.0

func tick(delta: float) -> Status:
	if bool(eval(&"condition")):
		return Status.SUCCESS
		
	var tout : float = eval(&"timeout") as float
	if tout > 0.0:
		_elapsed += delta
		if _elapsed >= tout:
			return Status.FAILURE
			
	return Status.RUNNING

func on_end(_status: Status) -> void:
	_elapsed = 0.0

func set_instruction() -> String: return "Wait until {condition} (timeout: {timeout}s)"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
