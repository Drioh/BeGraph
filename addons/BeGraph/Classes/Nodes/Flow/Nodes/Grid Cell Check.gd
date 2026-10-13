@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Grid Cell Check"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether a given cell coordinate in a TileMap, TileMapLayer, or GridMap is occupied."

@export_custom(PROPERTY_HINT_NODE_PATH_VALID_TYPES, BG.PROPERTY + "GridMap,TileMap,TileMapLayer") var map : NodePath = ^""
@export_custom(BG.HINT_NONE, BG.PROPERTY) var cell : Vector3i = Vector3i.ZERO

var _map : Node = null

func on_start() -> void:
	_map = eval(&"map", true)

func on_blackboard_property_changed(key: StringName) -> void:
	if key == get_blackboard_key(&"map"):
		_map = eval(&"map", true)

func tick(delta: float) -> Status:
	if _map == null or not is_instance_valid(_map):
		return abort("couldn't resolve map node")
		
	var cell_pos : Vector3i = eval(&"cell") as Vector3i
	var occupied : bool = false
	
	if _map is GridMap:
		occupied = _map.get_cell_item(cell_pos) != GridMap.INVALID_CELL_ITEM
	elif _map.has_method("get_cell_source_id"):
		occupied = _map.get_cell_source_id(Vector2i(cell_pos.x, cell_pos.y)) != -1
	else:
		return abort("map node is not a valid TileMap or GridMap")
		
	return tick_condition(delta, 0 if occupied else 1)

func on_end(_status: Status) -> void:
	_map = null

func set_instruction() -> String: return "Check cell {cell} on {map}"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Cell occupied", "Cell empty"])
