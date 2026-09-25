@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Character Velocity"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Sets {node}'s (a CharacterBody2D/3D) velocity to {velocity} and calls move_and_slide(), letting the engine handle collisions and sliding. For a CharacterBody2D, only the X/Y components are used.\n\nSucceeds once applied; fails if {node} can't be resolved or isn't a character body."

func set_instruction() -> String:
	return "Set {node}'s velocity to {velocity}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null or not _is_character_body(target):
		push_error("\"%s\" couldn't resolve a character body" % resource_name)
		return Status.FAILURE

	var velocity : Vector3 = get("velocity")
	if target is CharacterBody2D:
		target.velocity = Vector2(velocity.x, velocity.y)
	else:
		target.velocity = velocity
	target.move_and_slide()

	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""), PROPERTY_HINT_NODE_TYPE, "CharacterBody2D,CharacterBody3D", "", "", PROPERTY_USAGE_NODE_PATH_FROM_SCENE_ROOT)
	_add_behavior_property("velocity", Vector3.ZERO)

## Returns [code]true[/code] if [param n] is a character body this node supports.
func _is_character_body(n: Node) -> bool:
	return n is CharacterBody2D or n is CharacterBody3D
