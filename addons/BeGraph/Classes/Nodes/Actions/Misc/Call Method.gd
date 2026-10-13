@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Call Method"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Calls a method on target node and optionally stores its return value in a blackboard variable."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var method : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var arguments : Array = []
@export_custom(BG.HINT_NONE, BG.PROPERTY) var return_blackboard_key : StringName = &""

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null:
		return abort("couldn't resolve node")
		
	var method_name : StringName = eval(&"method")
	if method_name == &"":
		return abort("no method name set")
	if not target.has_method(method_name):
		return abort("node has no method '%s'" % method_name)
		
	var args : Array = eval(&"arguments")
	var result : Variant = target.callv(method_name, args)
	
	var ret_key : StringName = eval(&"return_blackboard_key")
	if ret_key != &"":
		var graph := get_graph()
		if graph != null:
			graph.set_blackboard_value(ret_key, result)
			
	return Status.SUCCESS

func set_instruction() -> String: return "Call {method} on {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
