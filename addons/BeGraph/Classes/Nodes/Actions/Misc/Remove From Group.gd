@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Remove From Group"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Removes a target node from a specified group."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var group : StringName = &""

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null:
		return abort("couldn't resolve node")
		
	var group_name : StringName = eval(&"group")
	if group_name == &"":
		return abort("no group name set")
		
	target.remove_from_group(group_name)
	return Status.SUCCESS

func set_instruction() -> String: return "Remove {node} from group {group}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
