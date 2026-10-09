@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Grid Cell Check"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"

@export_custom(PROPERTY_HINT_NODE_PATH_VALID_TYPES, BG.PROPERTY + "GridMap,TileMap,TileMapLayer") var map : NodePath = ^""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var cell : Vector3i = Vector3i.ZERO

func tick(delta: float) -> Status:
	var target_map := _resolve_node(eval(&"map"))
	if target_map == null:
		return abort("couldn't resolve map node")
		
	var cell_pos : Vector3i = eval(&"cell") as Vector3i
	var occupied : bool = false
	
	if target_map is GridMap:
		occupied = target_map.get_cell_item(cell_pos) != GridMap.INVALID_CELL_ITEM
	elif target_map.has_method("get_cell_source_id"):
		occupied = target_map.get_cell_source_id(Vector2i(cell_pos.x, cell_pos.y)) != -1
	else:
		return abort("map node is not a valid TileMap or GridMap")
		
	tick_condition(delta, 0 if occupied else 1)
	return Status.RUNNING

func set_instruction() -> String: return "Check cell {cell} on {map}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Cell occupied", "Cell empty"])
