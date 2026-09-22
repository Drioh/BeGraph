@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Breakpoint"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Debug utility node: whenever {enabled} is true and {condition} evaluates to true, triggers a debugger breakpoint (via GDScript's \"breakpoint\" keyword), pausing execution so the running graph's state can be inspected.\n\nHas no effect when no debugger is attached to the running game, or when {enabled}/{condition} is false.\n\nAlways ticks its successor afterwards and returns its status; fails if it has no successor."

func set_instruction() -> String:
	return "Breakpoint (enabled: {enabled}, if: {condition})"

func tick() -> Status:
	if _next_ref.size() == 0:
		return Status.FAILURE

	if get("enabled") and get("condition"):
		breakpoint

	return tick_next()

func set_node_category()->String: return "control_flow_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("enabled", true)
	_add_behavior_property("condition", true)
