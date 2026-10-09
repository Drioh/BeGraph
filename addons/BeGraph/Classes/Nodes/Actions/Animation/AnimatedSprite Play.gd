@tool
extends BehaviorNode

const DISPLAY_NAME : String = "AnimatedSprite Play"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY+"AnimatedSprite") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var animation : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var speed : float = 1.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var backwards : bool = false
@export_custom(BG.HINT_NONE, BG.PROPERTY) var wait_until_finished : bool = true

var _sprite_ref : Node

func on_start() -> void:
	_sprite_ref = _resolve_node(eval(&"node"))
	if not (_sprite_ref is AnimatedSprite2D or _sprite_ref is AnimatedSprite3D):
		abort("couldn't resolve AnimatedSprite2D/3D")
		return
		
	var anim : StringName = eval(&"animation") as StringName
	if _sprite_ref.sprite_frames == null or (anim != &"" and not _sprite_ref.sprite_frames.has_animation(anim)):
		abort("sprite frames do not have animation '%s'" % anim)
		return
		
	_sprite_ref.play(anim, eval(&"speed") as float, eval(&"backwards") as bool)

func tick(delta: float) -> Status:
	if not eval(&"wait_until_finished"):
		return tick_next(delta)
		
	if _sprite_ref.is_playing():
		return Status.RUNNING
		
	return tick_next(delta)

func set_instruction() -> String: return "Play {animation} on {node} at speed {speed}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
