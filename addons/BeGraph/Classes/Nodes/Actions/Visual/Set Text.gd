@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Text"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Writes {value} (converted to text, so numbers and other types from the blackboard work too) into the 'text' property of {node} (Label, RichTextLabel, Button, LineEdit, TextEdit, Label3D...), replacing the old text or appending to it depending on {mode}.\n\nSucceeds once applied; fails if {node} can't be resolved or has no text property."

enum Mode { REPLACE, APPEND }

func set_instruction() -> String:
	return "Set {node}'s text: {value} ({mode})"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not ("text" in target):
		push_error("\"%s\" couldn't resolve a node with a text property" % resource_name)
		return Status.FAILURE

	var text : String = str(get("value"))
	if get("mode") == Mode.APPEND:
		text = str(target.get("text")) + text
	target.set("text", text)

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("value", null, PROPERTY_HINT_NONE, "", "", "", PROPERTY_USAGE_NIL_IS_VARIANT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Replace,Append")
