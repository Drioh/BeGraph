@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Scale"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets or multiplies the scale of a Node2D or Node3D."

enum Mode { SET, MULTIPLY }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Set,Multiply") var mode : Mode = Mode.SET
@export_custom(BG.HINT_NONE, BG.PROPERTY) var scale : Vector3 = Vector3.ONE

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null or not ("scale" in target):
		return abort("couldn't resolve node with a scale property")
		
	var value : Vector3 = eval(&"scale") as Vector3
	var multiply : bool = (eval(&"mode") as Mode) == Mode.MULTIPLY
	
	if target is Node3D:
		target.scale = target.scale * value if multiply else value
	else:
		var val_2d := Vector2(value.x, value.y)
		target.scale = target.scale * val_2d if multiply else val_2d
		
	return Status.SUCCESS

func set_instruction() -> String: return "{mode} {node}'s scale: {scale}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
