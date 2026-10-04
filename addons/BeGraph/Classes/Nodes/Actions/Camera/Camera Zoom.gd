@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Camera Zoom"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Zooms {node} (a Camera2D/3D) to {zoom} over {duration}s (0 = instantly), with a smooth transition. A zoom of 2 shows everything twice as big, 0.5 half as big.\n\nCamera2D uses its zoom property; for Camera3D the field of view is divided by {zoom}, starting from the FOV the camera had the first time it was zoomed.\n\nReturns RUNNING while zooming and SUCCESS once finished; fails if {node} can't be resolved or isn't a camera."

const BASE_FOV_META : StringName = &"begraph_base_fov"

var _tween : Tween = null

func set_instruction() -> String:
	return "Zoom {node} to {zoom} over {duration}s"

func tick(delta:float) -> Status:
	if dirty:
		var camera : Node = _resolve_node(get("node"))
		if not (camera is Camera2D or camera is Camera3D):
			push_error("\"%s\" couldn't resolve a camera" % resource_name)
			return Status.FAILURE
		_start_zoom(camera)
		dirty = false

	if _tween != null and _tween.is_running():
		return Status.RUNNING

	_tween = null
	dirty = true
	tick_next(delta)
	return Status.SUCCESS

func _start_zoom(camera : Node) -> void:
	var zoom : float = maxf(get("zoom"), 0.001)
	var duration : float = get("duration")
	_tween = null

	if camera is Camera2D:
		var final_zoom : Vector2 = Vector2(zoom, zoom)
		if duration <= 0.0:
			camera.zoom = final_zoom
			return
		_tween = camera.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(camera, "zoom", final_zoom, duration)
		return

	var base_fov : float = camera.get_meta(BASE_FOV_META, camera.fov)
	camera.set_meta(BASE_FOV_META, base_fov)
	var final_fov : float = clampf(base_fov / zoom, 1.0, 179.0)
	if duration <= 0.0:
		camera.fov = final_fov
		return
	_tween = camera.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(camera, "fov", final_fov, duration)

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Camera2D,Camera3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("zoom", float(2.0))
	_add_behavior_property("duration", float(0.5))
