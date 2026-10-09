@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Check Animation Playing"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+"AnimationPlayer,AnimatedSprite2D,AnimatedSprite3D") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var animation : StringName = &""

func tick(delta: float) -> Status:
	var target : Node = _resolve_node(eval(&"node"))
	var playing : bool = false
	var current : String = ""
	
	if target is AnimationPlayer:
		playing = target.is_playing()
		current = String(target.current_animation)
	elif target is AnimatedSprite2D or target is AnimatedSprite3D:
		playing = target.is_playing()
		current = String(target.animation)
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
