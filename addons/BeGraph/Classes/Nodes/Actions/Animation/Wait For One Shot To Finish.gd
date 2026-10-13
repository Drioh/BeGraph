@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait For One Shot To Finish"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits until a one-shot node in an AnimationTree finishes execution."

@export_custom(PROPERTY_HINT_NODE_TYPE, BG.PROPERTY+ "AnimationTree") var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var one_shot : StringName = &""

var _tree_ref : AnimationTree

func on_start() -> void:
	_tree_ref = eval(&"node", true) as AnimationTree
	if _tree_ref == null:
		abort("couldn't resolve AnimationTree")

func tick(_delta: float) -> Status:
	if _tree_ref == null or not is_instance_valid(_tree_ref):
		return Status.FAILURE
	var shot_name : StringName = eval(&"one_shot")
	if bool(_tree_ref.get("parameters/%s/active" % shot_name)):
		return Status.RUNNING
	return Status.SUCCESS

func on_end(_status: Status) -> void:
	_tree_ref = null

func set_instruction() -> String: return "Wait for one shot {one_shot} on {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
