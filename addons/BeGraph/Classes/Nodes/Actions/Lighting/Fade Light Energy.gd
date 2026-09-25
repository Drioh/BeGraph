@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Fade Light Energy"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Smoothly ramps {node}'s (a Light2D or Light3D) brightness from its current value to {target_energy} over {duration}s - handy for fade in/out and flicker-free dimming.\n\nReturns RUNNING while fading and SUCCESS on completion; fails if {node} can't be resolved or isn't a light."

var _start_energy : float = 0.0
var _elapsed : float = 0.0
var _property_name : String = ""

func set_instruction() -> String:
	return "Fade {node} to energy {target_energy} over {duration}s"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_light(target):
		push_error("\"%s\" couldn't resolve a light" % resource_name)
		return Status.FAILURE

	if dirty:
		_property_name = "energy" if target is Light2D else "light_energy"
		_start_energy = target.get(_property_name)
		_elapsed = 0.0
		dirty = false

	_elapsed += delta
	var duration : float = get("duration")
	var target_energy : float = get("target_energy")

	if duration <= 0.0 or _elapsed >= duration:
		target.set(_property_name, target_energy)
		dirty = true
		tick_next(delta)
		return Status.SUCCESS

	target.set(_property_name, lerp(_start_energy, target_energy, _elapsed / duration))
	return Status.RUNNING

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "Light2D,Light3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("target_energy", float(1.0))
	_add_behavior_property("duration", float(1.0))

## Returns [code]true[/code] if [param n] is a light node this node supports.
func _is_light(n: Node) -> bool:
	return n is Light2D or n is Light3D
