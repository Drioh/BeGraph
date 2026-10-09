@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Change Scene"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { CHANGE, RELOAD }

@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Change,Reload" ) var mode : Mode = Mode.CHANGE
@export_custom(PROPERTY_HINT_FILE, BG.PROPERTY+"*.tscn,*.scn") var scene_path : String = ""

func tick(delta: float) -> Status:
	var agent := get_agent()
	if agent == null:
		return abort("owning behavior agent not found")
		
	var tree := agent.get_tree()
	var err : Error = OK
	
	if (eval(&"mode") as Mode) == Mode.RELOAD:
		err = tree.reload_current_scene()
	else:
		var path : String = eval(&"scene_path")
		if not ResourceLoader.exists(path):
			return abort("scene file '%s' does not exist" % path)
		err = tree.change_scene_to_file(path)
		
	if err != OK:
		return abort("failed to change scene with error code %d" % err)
		
	return Status.SUCCESS

func set_instruction() -> String: return "{mode} scene: {scene_path}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
