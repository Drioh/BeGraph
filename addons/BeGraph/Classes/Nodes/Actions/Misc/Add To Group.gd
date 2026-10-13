@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Add To Group"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Adds a target node to a specified group, optionally making the membership persistent across scene saves."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var group : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var persistent : bool = false

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null:
		return abort("couldn't resolve node")
		
	var group_name : StringName = eval(&"group")
	if group_name == &"":
		return abort("no group name set")
		
	target.add_to_group(group_name, eval(&"persistent") as bool)
	return Status.SUCCESS

func set_instruction() -> String: return "Add {node} to group {group}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
