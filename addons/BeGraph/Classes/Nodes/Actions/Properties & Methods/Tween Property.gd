@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Tween Property"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Interpolates a property on a target node to a new value over duration seconds using a Tween."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var property : String = ""
@export_custom(BG.HINT_NONE, BG.PROPERTY, PROPERTY_USAGE_NIL_IS_VARIANT) var target_value : Variant = null
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 1.0

var _tween : Tween = null

func on_start() -> void:
	var target := eval(&"node", true)
	if target == null:
		abort("couldn't resolve node")
		return
		
	_tween = target.create_tween()
	_tween.tween_property(target, eval(&"property"), eval(&"target_value"), eval(&"duration") as float)

func tick(_delta: float) -> Status:
	if _tween != null and _tween.is_running():
		return Status.RUNNING
	return Status.SUCCESS

func on_end(_status: Status) -> void:
	if _tween != null and _tween.is_valid() and _tween.is_running():
		_tween.kill()
	_tween = null

func set_instruction() -> String: return "Tween {node}'s {property} to {target_value} over {duration}s"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
