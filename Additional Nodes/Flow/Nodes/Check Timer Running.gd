@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Timer Running"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether a Timer node is running (not stopped)."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Timer") var node : NodePath = NodePath("")

var _target : Timer = null

func on_start() -> void:
	_target = eval(&"node", true) as Timer

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = eval(&"node", true) as Timer

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target):
		return abort("couldn't resolve Timer")
		
	return tick_condition(delta, 0 if not _target.is_stopped() else 1)

func on_end(_status: Status) -> void:
	_target = null

func set_instruction() -> String: return "Check if timer {node} is running"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Running", "Stopped"])
