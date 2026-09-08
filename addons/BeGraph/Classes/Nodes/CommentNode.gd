@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Comment"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/comment_node_icon.svg"

func set_instruction() -> String:return "{comment}"

func tick() -> Status: return Status.FAILURE

func set_node_category()->String:return "comment_node"

func set_input()->bool:return false

func set_output()->bool:return false

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void: _add_behavior_property("comment",String(""),PROPERTY_HINT_MULTILINE_TEXT)
