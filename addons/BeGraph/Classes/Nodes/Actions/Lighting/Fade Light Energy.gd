@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Fade Light Energy"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"Light2D,Light3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var target_energy : float = 1.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var duration : float = 1.0

var _light_node : Node = null
var _prop_name : String = ""
var _start_energy : float = 0.0
var _elapsed : float = 0.0

func on_start() -> void:
	_elapsed = 0.0
	_light_node = _resolve_node(eval(&"node"))
	if _light_node == null or not (_light_node is Light2D or _light_node is Light3D):
		abort("couldn't resolve light node")
		return
		
	_prop_name = "energy" if _light_node is Light2D else "light_energy"
	_start_energy = _light_node.get(_prop_name)

func tick(delta: float) -> Status:
	_elapsed += delta
	var dur : float = eval(&"duration") as float
	var target_e : float = eval(&"target_energy") as float
	
	if dur <= 0.0 or _elapsed >= dur:
		_light_node.set(_prop_name, target_e)
		return tick_next(delta)
		
	_light_node.set(_prop_name, lerpf(_start_energy, target_e, _elapsed / dur))
	return Status.RUNNING

func set_instruction() -> String: return "Fade {node} to energy {target_energy} over {duration}s"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
