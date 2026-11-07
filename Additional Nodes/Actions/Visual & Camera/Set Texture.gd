@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Texture"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Loads and assigns a texture to a target node's texture or icon property."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(PROPERTY_HINT_FILE, BG.PROPERTY+"*.png,*.jpg,*.jpeg,*.webp,*.svg,*.tres,*.res") var texture_path : String = ""

func tick(_delta: float) -> Status:
	var target :Node= eval(&"node", true)
	if target == null:
		return abort("couldn't resolve target node")
		
	var prop_name : String = ""
	if "texture" in target: prop_name = "texture"
	elif "icon" in target: prop_name = "icon"
	else: return abort("node has no texture or icon property")
	
	var path : String = eval(&"texture_path")
	var tex := load(path) as Texture2D
	if tex == null:
		return abort("couldn't load texture from path '%s'" % path)
		
	target.set(prop_name, tex)
	return Status.SUCCESS

func set_instruction() -> String: return "Set {node}'s texture to {texture_path}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
