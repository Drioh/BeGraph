@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Point In Radius"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

@export_custom(BG.HINT_NONE, BG.PROPERTY) var variable_name : StringName = &""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var center : Vector2 = Vector2.ZERO
@export_custom(BG.HINT_NONE, BG.PROPERTY) var radius : float = 100.0

func tick(delta: float) -> Status:
	var graph := get_graph()
	if graph == null:
		return abort("lost graph reference")
		
	var key : StringName = eval(&"variable_name") as StringName
	var variable := graph.get_blackboard_property(key)
	if variable == null:
		return abort("blackboard variable '%s' not found" % key)
		
	var rad : float = eval(&"radius") as float
	var offset := Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * sqrt(randf()) * rad
	variable.value = (eval(&"center") as Vector2) + offset
	return tick_next(delta)

func set_instruction() -> String: return "Set {variable_name} = random point around {center} (r={radius})"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
