@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Numeric Property"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets a numeric property by name on {node}: Set replaces it outright, Add/Multiply combine it with the current value via +/* . Works with int, float, Vector2/3/4 (and their int variants) since GDScript already overloads +/* for them; {value}'s type must match the property's own type or the operation will fail at runtime."

enum Mode { SET, ADD, MULTIPLY }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var property : String = ""
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Set,Add,Multiply") var mode : Mode = Mode.SET
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var value : Variant = null

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null:
		return abort("couldn't resolve node")

	var prop_name : String = eval(&"property")
	if prop_name == "" or not (prop_name in target):
		return abort("node has no property '%s'" % prop_name)

	var new_value : Variant = eval(&"value")
	match eval(&"mode") as Mode:
		Mode.ADD: new_value = target.get(prop_name) + new_value
		Mode.MULTIPLY: new_value = target.get(prop_name) * new_value

	target.set(prop_name, new_value)
	return tick_next(delta)

func set_instruction() -> String: return "{mode} {node}'s {property}: {value}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
