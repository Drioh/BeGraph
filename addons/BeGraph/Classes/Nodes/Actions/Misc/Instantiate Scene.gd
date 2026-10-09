@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Instantiate Scene"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(PROPERTY_HINT_FILE, BG.PROPERTY+"*.tscn,*.scn") var scene_path : String = ""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var parent : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var position : Vector3 = Vector3.ZERO

func tick(delta: float) -> Status:
	var path : String = eval(&"scene_path")
	var scene := load(path) as PackedScene
	if scene == null:
		return abort("couldn't load scene '%s'" % path)
		
	var parent_node := _resolve_node(eval(&"parent"))
	if parent_node == null:
		return abort("couldn't resolve parent node")
		
	var instance : Node = scene.instantiate()
	parent_node.add_child(instance)
	var pos : Vector3 = eval(&"position") as Vector3
	
	if instance is Node2D:
		instance.global_position = Vector2(pos.x, pos.y)
	elif instance is Node3D:
		instance.global_position = pos
		
	return tick_next(delta)

func set_instruction() -> String: return "Instantiate {scene_path} under {parent}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
