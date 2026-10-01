@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Camera Current"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Makes {node} (a Camera2D/3D) the active camera, deactivates it, or toggles it, depending on {mode}.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't a camera."

enum Mode { ON, OFF, TOGGLE }

func set_instruction() -> String:
	return "Set {node}'s current: {mode}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	var is_camera = target is Camera2D or target is Camera3D
	if target == null or !is_camera:
		push_error("\"%s\" couldn't resolve a camera" % resource_name)
		return Status.FAILURE

	match get("mode"):
		Mode.ON:
			target.make_current()
		Mode.OFF:
			if target is Camera2D:
				push_error("%s: target %s is a Camera2D, in order not to be the current camera, another Camera2D must be set as current in its stead."%[self,target])
			elif target is Camera3D:
				target.current=false
		Mode.TOGGLE:
			if target is Camera2D:
				if !target.is_current():
					target.make_current()
				else:
					push_error("%s: target %s is a Camera2D, in order not to be the current camera, another Camera2D must be set as current in its stead."%[self,target])
			elif target is Camera3D:
				target.current=false

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Camera2D,Camera3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "On,Off,Toggle")
