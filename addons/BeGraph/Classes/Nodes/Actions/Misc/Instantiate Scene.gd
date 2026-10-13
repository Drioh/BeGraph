@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Instantiate Scene"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Instantiates a PackedScene and adds it to parent, optionally storing the instance in a blackboard variable."

@export_custom(PROPERTY_HINT_FILE, BG.PROPERTY+"*.tscn,*.scn") var scene_path : String = ""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var parent : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var return_blackboard_key : StringName = &""

func tick(_delta: float) -> Status:
	var path : String = eval(&"scene_path")
	var scene := load(path) as PackedScene
	if scene == null:
		return abort("couldn't load scene '%s'" % path)
		
	var parent_node := eval(&"parent", true)
	if parent_node == null:
		var agent := get_agent()
		if agent != null and "actor" in agent:
			parent_node = agent.actor
			
	if parent_node == null:
		return abort("couldn't resolve parent node")
		
	var inst : Node = scene.instantiate()
	parent_node.add_child(inst)
	
	var ret_key : StringName = eval(&"return_blackboard_key")
	if ret_key != &"":
		var graph := get_graph()
		if graph != null:
			graph.set_blackboard_value(ret_key, inst)
			
	return Status.SUCCESS

func set_instruction() -> String: return "Instantiate {scene_path} under {parent}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
