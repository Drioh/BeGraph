@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Value"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

enum Mode { INT, FLOAT }

@export_custom(BG.HINT_NONE, BG.PROPERTY) var variable_name : StringName = &""
@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Int,Float") var mode : Mode = Mode.INT
@export_custom(BG.HINT_NONE, BG.PROPERTY) var min : float = 0.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var max : float = 1.0

func tick(delta: float) -> Status:
	var graph := get_graph()
	if graph == null:
		return abort("lost graph reference")
		
	var key : StringName = eval(&"variable_name") as StringName
	var variable := graph.get_blackboard_property(key)
	if variable == null:
		return abort("blackboard variable '%s' not found" % key)
		
	var min_val : float = eval(&"min") as float
	var max_val : float = eval(&"max") as float
	
	if (eval(&"mode") as Mode) == Mode.INT:
		variable.value = randi_range(int(min_val), int(max_val))
	else:
		variable.value = randf_range(min_val, max_val)
		
	return tick_next(delta)

func set_instruction() -> String: return "Set {variable_name} = random {mode} in [{min}, {max}]"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
