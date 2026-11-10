@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Camera Zoom"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Smoothly zooms a Camera2D (via zoom) or Camera3D (via FOV) over duration seconds."

const BASE_FOV_META : StringName = &"begraph_base_fov"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Camera2D,Camera3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var zoom : float = 2.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 0.5

var _tween : Tween = null

func on_start() -> void:
	var camera := eval(&"node", true)
	if not (camera is Camera2D or camera is Camera3D):
		abort("couldn't resolve a camera")
		return
		
	var zoom_val : float = maxf(eval(&"zoom") as float, 0.001)
	var dur : float = eval(&"duration") as float
	_tween = null
	
	if camera is Camera2D:
		var final_zoom := Vector2(zoom_val, zoom_val)
		if dur <= 0.0:
			camera.zoom = final_zoom
			return
		_tween = camera.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(camera, "zoom", final_zoom, dur)
	else:
		var base_fov : float = camera.get_meta(BASE_FOV_META, camera.fov)
		camera.set_meta(BASE_FOV_META, base_fov)
		var final_fov : float = clampf(base_fov / zoom_val, 1.0, 179.0)
		if dur <= 0.0:
			camera.fov = final_fov
			return
		_tween = camera.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_property(camera, "fov", final_fov, dur)

func tick(_delta: float) -> Status:
	if _tween != null and _tween.is_running(): return Status.RUNNING
	
	return Status.SUCCESS

func on_end(_status: Status) -> void:
	if _tween != null and _tween.is_valid() and _tween.is_running():
		_tween.kill()
	_tween = null

func set_instruction() -> String: return "Zoom {node} to {zoom} over {duration}s"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
