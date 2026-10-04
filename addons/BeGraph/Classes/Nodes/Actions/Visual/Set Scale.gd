@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Scale"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets the scale of {node} (a Node2D, Node3D or Control) to {scale}, or multiplies its current scale by it, depending on {mode}. 2D nodes and Controls only use the X/Y components.\n\nSucceeds once applied; fails if {node} can't be resolved or has no scale."

enum Mode { SET, MULTIPLY }

func set_instruction() -> String:
	return "{mode} {node}'s scale: {scale}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not (target is Node3D or "scale" in target):
		push_error("\"%s\" couldn't resolve a node with a scale" % resource_name)
		return Status.FAILURE

	var value : Vector3 = get("scale")
	var multiply : bool = get("mode") == Mode.MULTIPLY
	if target is Node3D:
		target.scale = target.scale * value if multiply else value
	else:
		var value_2d : Vector2 = Vector2(value.x, value.y)
		target.scale = target.scale * value_2d if multiply else value_2d

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Set,Multiply")
	_add_behavior_property("scale", Vector3.ONE)
