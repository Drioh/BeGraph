@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Flip Sprite"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { ON, OFF, TOGGLE }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Horizontal,Vertical") var axis : int = 0
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"On,Off,Toggle") var mode : Mode = Mode.TOGGLE

func tick(delta: float) -> Status:
	var target := _resolve_node(eval(&"node"))
	if target == null:
		return abort("couldn't resolve node")
		
	var horizontal : bool = (eval(&"axis") as int) == 0
	var flip_prop : String = "flip_h" if horizontal else "flip_v"
	
	if flip_prop in target:
		target.set(flip_prop, _wanted(bool(target.get(flip_prop))))
	elif target is Node2D:
		var s : Vector2 = target.scale
		var flipped : bool = s.x < 0.0 if horizontal else s.y < 0.0
		var factor : float = -1.0 if _wanted(flipped) else 1.0
		if horizontal: s.x = absf(s.x) * factor
		else: s.y = absf(s.y) * factor
		target.scale = s
	else:
		return abort("node cannot be flipped")
		
	return tick_next(delta)

func _wanted(current : bool) -> bool:
	match eval(&"mode") as Mode:
		Mode.ON: return true
		Mode.OFF: return false
		_: return not current

func set_instruction() -> String: return "Flip {node} ({axis}): {mode}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
