@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Animation Tree Active"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether an AnimationTree node is currently active."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AnimationTree") var node : NodePath = NodePath("")

var _target : AnimationTree = null

func on_start() -> void:
	_target = eval(&"node", true) as AnimationTree

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = eval(&"node", true) as AnimationTree

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target):
		return abort("couldn't resolve AnimationTree")
		
	return tick_condition(delta, 0 if _target.active else 1)

func on_end(_status: Status) -> void:
	_target = null

func set_instruction() -> String: return "Check {node}'s active state"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Active", "Inactive"])
