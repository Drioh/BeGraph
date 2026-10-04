@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Texture"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Loads the texture at {texture_path} and assigns it to {node}: its 'texture' property (Sprite2D, Sprite3D, TextureRect, NinePatchRect...) or, if it has none, its 'icon' property (Button...).\n\nSucceeds once applied; fails if {node} can't be resolved, doesn't have either property or the file can't be loaded as a Texture2D."

func set_instruction() -> String:
	return "Set {node}'s texture to {texture_path}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	var property_name : String = ""
	if "texture" in target:
		property_name = "texture"
	elif "icon" in target:
		property_name = "icon"
	else:
		push_error("\"%s\": \"%s\" has no texture/icon property" % [resource_name, target])
		return Status.FAILURE

	var texture : Texture2D = load(get("texture_path")) as Texture2D
	if texture == null:
		push_error("\"%s\" couldn't load texture \"%s\"" % [resource_name, get("texture_path")])
		return Status.FAILURE

	target.set(property_name, texture)
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("texture_path", "", PROPERTY_HINT_FILE, "*.png,*.jpg,*.jpeg,*.webp,*.svg,*.tres,*.res")
