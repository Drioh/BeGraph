@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Property"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets an arbitrary property by name on {node} to {value}. Works on any property exposed through set()/get() (built-in or scripted); fails at runtime if {property} doesn't exist on {node}. Use this for a one-off assignment; if you need On/Off/Toggle, Add/Multiply, or Replace/Append semantics, use the dedicated setter node instead."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var property : String = ""
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var value : Variant = null

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null:
		return abort("couldn't resolve node")

	var prop_name : String = eval(&"property")
	if prop_name == "":
		return abort("no property name set")
	if not (prop_name in target):
		return abort("node has no property '%s'" % prop_name)

	target.set(prop_name, eval(&"value"))
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s {property} value: {value}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
