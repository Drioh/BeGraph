@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Call Group"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Calls a method with arguments on all members of a group in the SceneTree."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var group : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var method : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var arguments : Array = []

func tick(_delta: float) -> Status:
	var agent := get_agent()
	if agent == null:
		return abort("owning BehaviorAgent not found")
		
	var group_name : StringName = eval(&"group")
	var method_name : StringName = eval(&"method")
	if group_name == &"" or method_name == &"":
		return abort("group or method name is empty")
		
	var args : Array = eval(&"arguments")
	var tree : SceneTree = agent.get_tree()
	
	match args.size():
		0: tree.call_group(group_name, method_name)
		1: tree.call_group(group_name, method_name, args[0])
		2: tree.call_group(group_name, method_name, args[0], args[1])
		3: tree.call_group(group_name, method_name, args[0], args[1], args[2])
		4: tree.call_group(group_name, method_name, args[0], args[1], args[2], args[3])
		_: tree.call_group_flags(0, group_name, method_name, args)
		
	return Status.SUCCESS

func set_instruction() -> String: return "Call {method} on group {group}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
