@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Set Process Enabled"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Turns the _process (if {idle_process} is true) and/or the _physics_process (if {physics_process} is true) callbacks of {node} on, off, or toggles them, depending on {mode}.\n\nUnlike 'Set Process Mode' it doesn't touch the pause behavior: it calls set_process() / set_physics_process().\n\nSucceeds once applied; fails if {node} can't be resolved."

enum Mode { ON, OFF, TOGGLE }

func set_instruction() -> String:
	return "Set {node}'s processing: {mode}"

func tick(delta:float) -> Status:
	var target : Node = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return Status.FAILURE

	if get("idle_process"):
		target.set_process(_wanted(target.is_processing()))
	if get("physics_process"):
		target.set_physics_process(_wanted(target.is_physics_processing()))

	tick_next(delta)
	return Status.SUCCESS

## Returns the state to apply, given the [param current] one.
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
	_add_behavior_property("mode", 0, PROPERTY_HINT_ENUM, "On,Off,Toggle")
	_add_behavior_property("idle_process", true)
	_add_behavior_property("physics_process", true)
