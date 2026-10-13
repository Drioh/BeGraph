@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Camera Current"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether a Camera2D or Camera3D node is currently active."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Camera2D,Camera3D") var node : NodePath = NodePath("")

var _target : Node = null

func on_start() -> void:
	_target = eval(&"node", true)

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = eval(&"node", true)

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target) or not (_target is Camera2D or _target is Camera3D):
		return abort("couldn't resolve camera")
		
	var is_curr : bool = _target.is_current() if _target is Camera2D else _target.current
	return tick_condition(delta, 0 if is_curr else 1)

func on_end(_status: Status) -> void:
	_target = null

func set_instruction() -> String: return "Check if {node} is current"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Current", "Not current"])
