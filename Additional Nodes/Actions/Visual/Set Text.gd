@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Text"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Replaces or appends text on a node exposing a text property."

enum Mode { REPLACE, APPEND }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var value : Variant = null
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Replace,Append") var mode : Mode = Mode.REPLACE

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null or not ("text" in target):
		return abort("couldn't resolve node with a text property")
		
	var new_txt : String = str(eval(&"value"))
	if (eval(&"mode") as Mode) == Mode.APPEND:
		new_txt = str(target.get("text")) + new_txt
		
	target.set("text", new_txt)
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s text: {value} ({mode})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
