@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Screen Shake"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Camera2D,Camera3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var strength : float = 10.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 0.3

var _camera : Node = null
var _tween : Tween = null
var _base_offset : Vector2 = Vector2.ZERO

func on_start() -> void:
	_camera = _resolve_node(eval(&"node"))
	if not (_camera is Camera2D or _camera is Camera3D):
		abort("couldn't resolve a camera")
		return
		
	_base_offset = _read_offset()
	_tween = _camera.create_tween()
	_tween.tween_method(_apply_shake, 1.0, 0.0, eval(&"duration") as float)
	_tween.tween_callback(_restore)

func tick(delta: float) -> Status:
	if _tween != null and _tween.is_running():
		return Status.RUNNING
	return tick_next(delta)

func _apply_shake(intensity : float) -> void:
	if is_instance_valid(_camera):
		var amount : float = (eval(&"strength") as float) * intensity
		_write_offset(_base_offset + Vector2.RIGHT.rotated(randf() * TAU) * randf() * amount)

func _restore() -> void:
	if is_instance_valid(_camera):
		_write_offset(_base_offset)

func on_end(_status: Status) -> void:
	if _tween != null and _tween.is_valid() and _tween.is_running():
		_tween.kill()
	_restore()

func _read_offset() -> Vector2:
	return _camera.offset if _camera is Camera2D else Vector2(_camera.h_offset, _camera.v_offset)

func _write_offset(offset : Vector2) -> void:
	if _camera is Camera2D: _camera.offset = offset
	else: _camera.h_offset = offset.x; _camera.v_offset = offset.y

func set_instruction() -> String: return "Shake {node} (strength {strength}) for {duration}s"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
