@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Breakpoint"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var enabled : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var condition : bool = true

func tick(delta: float) -> Status:
	if _next_ref.size() == 0:
		return Status.FAILURE
		
	if bool(eval(&"enabled")) and bool(eval(&"condition")):
		breakpoint
		
	return tick_next(delta)

func set_instruction() -> String: return "Breakpoint (enabled: {enabled}, if: {condition})"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
