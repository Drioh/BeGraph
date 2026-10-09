@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Process Enabled"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { ON, OFF, TOGGLE }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"On,Off,Toggle") var mode : Mode = Mode.ON
@export_custom(BG.HINT_NONE, BG.PROPERTY) var idle_process : bool = true
@export_custom(BG.HINT_NONE, BG.PROPERTY) var physics_process : bool = true

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null:
		return abort("couldn't resolve node")
		
	if eval(&"idle_process"):
		target.set_process(_wanted(target.is_processing()))
	if eval(&"physics_process"):
		target.set_physics_process(_wanted(target.is_physics_processing()))
		
	return tick_next(delta)

func _wanted(current : bool) -> bool:
	match eval(&"mode") as Mode:
		Mode.ON: return true
		Mode.OFF: return false
		_: return not current

func set_instruction() -> String: return "Set {node}'s processing: {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
