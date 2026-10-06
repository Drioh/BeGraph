@tool
extends BehaviorNode
class_name BehaviorComment

const DISPLAY_NAME : String = "Comment"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/comment_node_icon.svg"
const DISPLAY_SCENE : String = "res://addons/BeGraph/UI/BehaviorGraphComment.tscn"
const DISPLAY_INFO : String = "Visual-only annotation node. Shows a title and a multiline comment; has no input/output slots and is never ticked during execution."

@export var comment_title : String
@export var comment_text : String
@export var node_size : Vector2
@export var border_color: String = "BeGraph/colors/node_colors/comment_node/border"
@export var background_color: String = "BeGraph/colors/node_colors/comment_node/background"

func set_instruction() -> String:return "{comment}"

func tick(delta:float) -> Status: return Status.FAILURE

func set_node_category()->String:return "comment_node"

func set_input()->bool:return false

func set_output()->bool:return false

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void: _add_behavior_property("comment",String(""),PROPERTY_HINT_MULTILINE_TEXT)
