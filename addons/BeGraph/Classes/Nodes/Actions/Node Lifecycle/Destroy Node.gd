@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Destroy Node"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Destroys {node} by calling queue_free(). If {clear_blackboard_key} is set, also clears the blackboard variable holding the reference."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var clear_blackboard_key : StringName = &""

func tick(_delta: float) -> Status:
	var target := eval(&"node", true)
	if target == null:
		return abort("couldn't resolve node to destroy")

	target.queue_free()

	var bb_key : StringName = eval(&"clear_blackboard_key")
	if bb_key != &"":
		var graph := get_graph()
		if graph != null and graph.get_blackboard_property(bb_key) != null:
			graph.set_blackboard_value(bb_key, null)

	return Status.SUCCESS

func set_instruction() -> String: return "Destroy {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
