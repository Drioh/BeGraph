@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Visible"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {node} (a CanvasItem or Node3D) is currently visible."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"CanvasItem,Node3D") var node : NodePath = NodePath("")

var _target : Node = null

func on_start() -> void:
	_target = _resolve_node(eval(&"node"))

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = _resolve_node(eval(&"node"))

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target) or not (_target is CanvasItem or _target is Node3D):
		return abort("couldn't resolve visual node")
		
	if _target.visible:
		tick_condition(delta, 0)
	else:
		tick_condition(delta, 1)
		
	return Status.RUNNING

func set_instruction() -> String: return "Check {node}'s visibility"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray:
	return PackedStringArray(["Visible", "Hidden"])
