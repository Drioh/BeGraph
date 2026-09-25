@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Tween Property"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Animates {node}'s {property} (e.g. \"position\", \"scale\", \"modulate:a\") to {target_value} over {duration}s, using a Tween.\n\nReturns RUNNING while animating and SUCCESS on completion; fails if {node} can't be resolved."

var _tween : Tween = null

func set_instruction() -> String:
	return "Tween {node}'s {property} to {target_value} over {duration}s"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	if dirty:
		_tween = target.create_tween()
		_tween.tween_property(target, get("property"), get("target_value"), get("duration"))
		dirty = false

	if _tween.is_running():
		return Status.RUNNING

	dirty = true
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("property", "")
	_add_behavior_property("target_value", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("duration", float(1.0))
