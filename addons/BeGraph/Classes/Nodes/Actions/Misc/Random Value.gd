@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Random Value"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Generates a random float, int, or picks an element from an array, and stores the result in a blackboard variable."

enum Mode { FLOAT_RANGE, INT_RANGE, PICK_FROM_ARRAY }

@export_custom(PROPERTY_HINT_ENUM, BG.PROPERTY+"Float Range,Int Range,Pick From Array") var mode : Mode = Mode.FLOAT_RANGE
@export_custom(BG.HINT_NONE, BG.PROPERTY) var min_value : float = 0.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var max_value : float = 1.0
@export_custom(BG.HINT_NONE, BG.PROPERTY) var options : Array = []
@export_custom(BG.HINT_NONE, BG.PROPERTY) var blackboard_key : StringName = &""

func tick(_delta: float) -> Status:
	var key : StringName = eval(&"blackboard_key")
	if key == &"":
		return abort("no blackboard key set")
		
	var graph := get_graph()
	if graph == null:
		return abort("lost graph reference")
		
	var result : Variant
	match eval(&"mode") as Mode:
		Mode.FLOAT_RANGE:
			result = randf_range(eval(&"min_value") as float, eval(&"max_value") as float)
		Mode.INT_RANGE:
			result = randi_range(int(eval(&"min_value")), int(eval(&"max_value")))
		Mode.PICK_FROM_ARRAY:
			var arr : Array = eval(&"options")
			if arr.is_empty():
				return abort("options array is empty")
			result = arr[randi() % arr.size()]
			
	graph.set_blackboard_value(key, result)
	return Status.SUCCESS

func set_instruction() -> String: return "Store random {mode} in {blackboard_key}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
