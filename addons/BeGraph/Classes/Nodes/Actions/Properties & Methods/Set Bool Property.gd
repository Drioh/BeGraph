@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Bool Property"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets a boolean property by name on {node} to On (true), Off (false), or Toggle (inverts the current value)."

enum Mode { ON, OFF, TOGGLE }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var property : String = ""
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"On,Off,Toggle") var mode : Mode = Mode.ON

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null:
		return abort("couldn't resolve node")

	var prop_name : String = eval(&"property")
	if prop_name == "" or not (prop_name in target):
		return abort("node has no property '%s'" % prop_name)

	var new_value : bool
	match eval(&"mode") as Mode:
		Mode.ON: new_value = true
		Mode.OFF: new_value = false
		Mode.TOGGLE: new_value = not bool(target.get(prop_name))

	target.set(prop_name, new_value)
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s {property}: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
