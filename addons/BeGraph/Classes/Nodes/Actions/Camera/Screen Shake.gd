@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Screen Shake"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Shakes {node} (a Camera2D/3D) for {duration}s by moving its offset randomly up to {strength} units (pixels for Camera2D, units of h_offset/v_offset for Camera3D), fading out to zero. The original offset is restored at the end.\n\nReturns RUNNING while shaking and SUCCESS once finished; fails if {node} can't be resolved or isn't a camera."

var _tween : Tween = null
var _camera : Node = null
var _base_offset : Vector2 = Vector2.ZERO

func set_instruction() -> String:
	return "Shake {node} (strength {strength}) for {duration}s"

func tick(delta:float) -> Status:
	if dirty:
		_camera = _resolve_node(get("node"))
		if not (_camera is Camera2D or _camera is Camera3D):
			push_error("\"%s\" couldn't resolve a camera" % resource_name)
			return Status.FAILURE
		_base_offset = _read_offset()
		_tween = _camera.create_tween()
		_tween.tween_method(_apply_shake, 1.0, 0.0, get("duration"))
		_tween.tween_callback(_restore)
		dirty = false

	if _tween != null and _tween.is_running():
		return Status.RUNNING

	dirty = true
	tick_next(delta)
	return Status.SUCCESS

## Called by the tween with [param intensity] going from 1 to 0.
func _apply_shake(intensity : float) -> void:
	if not is_instance_valid(_camera):
		return
	var amount : float = float(get("strength")) * intensity
	_write_offset(_base_offset + Vector2.RIGHT.rotated(randf() * TAU) * randf() * amount)

func _restore() -> void:
	if is_instance_valid(_camera):
		_write_offset(_base_offset)

func _read_offset() -> Vector2:
	if _camera is Camera2D:
		return _camera.offset
	return Vector2(_camera.h_offset, _camera.v_offset)

func _write_offset(offset : Vector2) -> void:
	if _camera is Camera2D:
		_camera.offset = offset
	else:
		_camera.h_offset = offset.x
		_camera.v_offset = offset.y

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Camera2D,Camera3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("strength", float(10.0))
	_add_behavior_property("duration", float(0.3))
