@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Animation Playing"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AnimationPlayer,AnimatedSprite2D,AnimatedSprite3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var animation : StringName = &""

var _target : Node = null

func on_start() -> void:
	_target = _resolve_node(eval(&"node"))

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"node"):
		_target = _resolve_node(eval(&"node"))

func tick(delta: float) -> Status:
	if _target == null or not is_instance_valid(_target):
		return abort("couldn't resolve an animation player or animated sprite")
		
	var playing : bool = false
	var current : String = ""
	
	if _target is AnimationPlayer:
		playing = _target.is_playing()
		current = String(_target.current_animation)
	elif _target is AnimatedSprite2D or _target is AnimatedSprite3D:
		playing = _target.is_playing()
		current = String(_target.animation)
	else:
		return abort("couldn't resolve an animation player or animated sprite")
		
	var wanted : String = String(eval(&"animation"))
	if wanted != "":
		playing = playing and current == wanted
		
	tick_condition(delta, 0 if playing else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check if {node} is playing {animation}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Playing", "Not playing"])
