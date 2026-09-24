@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Instantiate Scene"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Loads the PackedScene at {scene_path}, instantiates it under {parent} and places it at {position} (read as 2D or 3D depending on the instance type).\n\nSucceeds once added; fails if the scene or parent can't be resolved."

func set_instruction() -> String:
	return "Instantiate {scene_path} under {parent}"

func tick() -> Status:
	var scene : PackedScene = load(get("scene_path")) as PackedScene
	if scene == null:
		push_error("\"%s\" non riesce a caricare la scena \"%s\"" % [resource_name, get("scene_path")])
		return Status.FAILURE

	var parent : Node = _resolve_node(get("parent"))
	if parent == null:
		push_error("\"%s\" non riesce a risolvere il nodo padre" % resource_name)
		return Status.FAILURE

	var instance : Node = scene.instantiate()
	parent.add_child(instance)

	var pos : Vector3 = get("position")
	if instance is Node2D:
		instance.global_position = Vector2(pos.x, pos.y)
	elif instance is Node3D:
		instance.global_position = pos

	tick_next()
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("scene_path", "")
	_add_behavior_property("parent", NodePath(""))
	_add_behavior_property("position", Vector3.ZERO)
