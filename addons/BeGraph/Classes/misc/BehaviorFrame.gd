@tool
## Persistent description of a frame ([GraphFrame]) inside a [BehaviorGraph]: it only groups other nodes visually and is never ticked.
class_name BehaviorFrame
extends BehaviorNode

const DISPLAY_NAME : String = "Frame"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/comment_node_icon.svg"
const DISPLAY_INFO : String = "Visual-only frame that groups other nodes. Never ticked during execution."

@export var frame_title : String = ""
@export var tint_color : Color = Color(0.28, 0.4, 0.62, 0.7)
## If true the frame shrinks/grows automatically to wrap its attached nodes.
@export var autoshrink : bool = true
@export var frame_size : Vector2 = Vector2(600, 400)
## Names of the nodes attached to this frame.
@export var attached_nodes : Array[StringName] = []

func set_instruction() -> String: return ""
func tick(delta:float) -> Status: return Status.FAILURE
func set_node_category() -> String: return "frame_node"
func set_input() -> bool: return false
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_properties() -> void: return
