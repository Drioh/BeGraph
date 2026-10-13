@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Change Scene"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Changes the currently active scene to the scene file specified by scene_path."

@export_custom(PROPERTY_HINT_FILE, BG.PROPERTY+"*.tscn,*.scn") var scene_path : String = ""

func tick(_delta: float) -> Status:
	var agent := get_agent()
	if agent == null:
		return abort("owning behavior agent not found")
		
	var path : String = eval(&"scene_path")
	var err := agent.get_tree().change_scene_to_file(path)
	if err != OK:
		return abort("failed to change scene to '%s' (error %d)" % [path, err])
		
	return Status.SUCCESS

func set_instruction() -> String: return "Change scene to {scene_path}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
