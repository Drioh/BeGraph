@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Bool Property"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets a boolean property by name on {node}: On, Off, or Toggle (reads the current value first). {invert} flips the computed value before writing - use it for properties that read backwards relative to the concept you want to express (e.g. property 'disabled', mode On meaning 'enabled' -> invert: true)."

enum Mode { ON, OFF, TOGGLE }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var property : String = ""
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"On,Off,Toggle") var mode : Mode = Mode.ON
@export_custom(BG.HINT_NONE, BG.PROPERTY) var invert : bool = false

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null:
		return abort("couldn't resolve node")

	var prop_name : String = eval(&"property")
	if prop_name == "" or not (prop_name in target):
		return abort("node has no property '%s'" % prop_name)

	var current : bool = bool(target.get(prop_name))
	var wanted : bool = _wanted(current)
	if eval(&"invert"):
		wanted = not wanted

	target.set(prop_name, wanted)
	return tick_next(delta)

func _wanted(current : bool) -> bool:
	match eval(&"mode") as Mode:
		Mode.ON: return true
		Mode.OFF: return false
		_: return not current

func set_instruction() -> String: return "Set {node}'s {property}: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
