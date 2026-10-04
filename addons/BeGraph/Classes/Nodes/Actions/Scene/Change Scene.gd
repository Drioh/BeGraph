@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Change Scene"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Depending on {mode}, switches the game to the scene file {scene_path} or reloads the current scene.\n\nThe change happens at the end of the frame and frees the current scene (this graph included), so the node has no successor.\n\nReturns SUCCESS once requested; fails if the file doesn't exist or the engine refuses the change."

enum Mode { CHANGE, RELOAD }

func set_instruction() -> String:
	return "{mode} scene: {scene_path}"

func tick(delta:float) -> Status:
	var agent : Node = get_agent()
	if agent == null:
		return Status.FAILURE

	var tree : SceneTree = agent.get_tree()
	var error : int
	if get("mode") == Mode.RELOAD:
		error = tree.reload_current_scene()
	else:
		var path : String = get("scene_path")
		if not ResourceLoader.exists(path):
			push_error("\"%s\": scene \"%s\" doesn't exist" % [resource_name, path])
			return Status.FAILURE
		error = tree.change_scene_to_file(path)

	if error != OK:
		push_error("\"%s\" couldn't change scene (error %d)" % [resource_name, error])
		return Status.FAILURE
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "Change,Reload")
	_add_behavior_property("scene_path", "", PROPERTY_HINT_FILE, "*.tscn,*.scn")
