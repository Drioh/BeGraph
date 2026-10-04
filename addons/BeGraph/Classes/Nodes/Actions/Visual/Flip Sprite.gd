@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Flip Sprite"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Mirrors {node} on the {axis} axis: turns the flip on, off, or toggles it, depending on {mode}.\n\nUses flip_h / flip_v when {node} has them (Sprite2D, AnimatedSprite2D, Sprite3D, AnimatedSprite3D); any other Node2D is mirrored by negating the matching component of its scale.\n\nSucceeds once applied; fails if {node} can't be resolved or can't be flipped."

enum Mode { ON, OFF, TOGGLE }

func set_instruction() -> String:
	return "Flip {node} ({axis}): {mode}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	var horizontal : bool = get("axis") == 0
	var flip_property : String = "flip_h" if horizontal else "flip_v"

	if flip_property in target:
		target.set(flip_property, _wanted(bool(target.get(flip_property))))
	elif target is Node2D:
		var s : Vector2 = target.scale
		var flipped : bool = s.x < 0.0 if horizontal else s.y < 0.0
		var factor : float = -1.0 if _wanted(flipped) else 1.0
		if horizontal:
			s.x = absf(s.x) * factor
		else:
			s.y = absf(s.y) * factor
		target.scale = s
	else:
		push_error("\"%s\": \"%s\" can't be flipped" % [resource_name, target])
		return Status.FAILURE

	tick_next(delta)
	return Status.SUCCESS

## Returns the flip state that must be applied, given the [param current] one.
func _wanted(current : bool) -> bool:
	match get("mode"):
		Mode.ON: return true
		Mode.OFF: return false
	return not current

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("axis", 0, PROPERTY_HINT_ENUM, "Horizontal,Vertical")
	_add_behavior_property("mode", 2, PROPERTY_HINT_ENUM, "On,Off,Toggle")
