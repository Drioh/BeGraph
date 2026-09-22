@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Modulate"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets {color} on either the \"modulate\" or \"self_modulate\" property of {node}, chosen via {mode}.\n\nBefore assigning, dynamically verifies (through the target's property list) that {node} actually exposes the property selected by {mode}, instead of assuming it does; most CanvasItems (Node2D, Control...) expose both, plain Nodes or Node3Ds don't.\n\nSucceeds once applied; fails if {node} can't be resolved or doesn't have the property selected by {mode}."

enum Mode { MODULATE, SELF_MODULATE }

func set_instruction() -> String:
	return "Set {node}'s {mode} to {color}"

func tick() -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node to modulate" % resource_name)
		return Status.FAILURE

	var property_name : String = "modulate" if get("mode") == Mode.MODULATE else "self_modulate"

	if not target is CanvasItem:
		push_error("\"%s\": \"%s\" is not a CanvasItem" % [resource_name, target])
		return Status.FAILURE

	target.set(property_name, get("color"))
	return Status.SUCCESS

func set_node_category()->String: return "action_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "CanvasItem", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Modulate,SelfModulate")
	_add_behavior_property("color", Color.WHITE)
