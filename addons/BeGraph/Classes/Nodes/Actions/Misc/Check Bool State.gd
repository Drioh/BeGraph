@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Bool State"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Reads a boolean property or a zero-argument boolean method, by name, on {node} and branches on it. {invert} flips the read value before branching - useful when the underlying name reads backwards relative to the condition you want (e.g. property 'disabled' to ask 'is it enabled?')."

enum Source { PROPERTY, METHOD }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Property,Method") var source : Source = Source.PROPERTY
@export_custom(BG.HINT_NONE, BG.PROPERTY) var member_name : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var invert : bool = false

var _target : Node = null

func on_start() -> void:
	_target = _resolve_node(eval(&"node"))

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = _resolve_node(eval(&"node"))

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target):
		return abort("couldn't resolve node")

	var member : StringName = eval(&"member_name")
	if member == &"":
		return abort("no property/method name set")

	var result : bool
	match eval(&"source") as Source:
		Source.PROPERTY:
			if not (String(member) in _target):
				return abort("node has no property '%s'" % member)
			result = bool(_target.get(member))
		Source.METHOD:
			if not _target.has_method(member):
				return abort("node has no method '%s'" % member)
			result = bool(_target.call(member))

	if eval(&"invert"):
		result = not result

	tick_condition(delta, 0 if result else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check {node}'s {member_name} ({source})"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["True", "False"])
