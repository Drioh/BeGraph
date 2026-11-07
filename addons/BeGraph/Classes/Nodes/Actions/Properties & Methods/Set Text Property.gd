@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Text Property"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets a string property by name on {node}: Replace overwrites it, Append reads the current value, stringifies it, and concatenates {value} after it."

enum Mode { REPLACE, APPEND }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var property : String = "text"
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Replace,Append") var mode : Mode = Mode.REPLACE
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var value : Variant = null

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null:
		return abort("couldn't resolve node")

	var prop_name : String = eval(&"property")
	if prop_name == "" or not (prop_name in target):
		return abort("node has no property '%s'" % prop_name)

	var new_txt : String = str(eval(&"value"))
	if (eval(&"mode") as Mode) == Mode.APPEND:
		new_txt = str(target.get(prop_name)) + new_txt

	target.set(prop_name, new_txt)
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s {property}: {value} ({mode})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
