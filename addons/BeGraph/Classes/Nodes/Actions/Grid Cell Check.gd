@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Grid Cell Check"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Checks whether {cell} is occupied on {map} (TileMap or GridMap, auto-detected) and branches to 'Cell occupied' or 'Cell empty'.\n\nFails if {map} cannot be resolved."

var _map : Node
var _is_3d : bool = false
var first_time : bool = true

func set_instruction() -> String:
	return "Check cell {cell} on {map}"

func tick() -> Status:
	if first_time:
		_map = _resolve_node(get("map"))
		if _map == null:
			push_error("\"%s\" couldn't resolve map node" % resource_name)
			return Status.FAILURE
		_is_3d = _map is GridMap
		first_time = false

	var cell : Vector3i = get("cell")
	var occupied : bool

	if _is_3d:
		occupied = _map.get_cell_item(cell) != GridMap.INVALID_CELL_ITEM
	else:
		occupied = _map.get_cell_source_id(Vector2i(cell.x, cell.y)) != -1

	if occupied:
		tick_condition(0)
	else:
		tick_condition(1)
	return Status.RUNNING

func set_node_category()->String: return "control_flow_node"
func set_input()->bool: return true
func set_output()->bool : return false
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("map", NodePath(""))
	_add_behavior_property("cell", Vector3i.ZERO)

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Cell occupied",
		"Cell empty"
	])
