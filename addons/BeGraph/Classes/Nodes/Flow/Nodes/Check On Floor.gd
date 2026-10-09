@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check On Floor"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"CharacterBody2D,CharacterBody3D") var node : NodePath = NodePath("")

var _target : Node = null

func on_start() -> void:
	_target = _resolve_node(eval(&"node"))

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = _resolve_node(eval(&"node"))

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target) or not (_target is CharacterBody2D or _target is CharacterBody3D):
		return abort("couldn't resolve character body")
		
	tick_condition(delta, 0 if _target.is_on_floor() else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check if {node} is on floor"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["On floor", "In air"])
