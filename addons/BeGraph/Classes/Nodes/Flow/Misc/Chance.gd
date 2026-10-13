@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Chance"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/control_flow_node_icon.svg"
const DISPLAY_INFO : String = "Rolls a random percentage chance against {probability}% on start and branches to Success or Failure accordingly."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var probability : float = 50.0

var _chosen_branch : int = 0

func on_start() -> void:
	_chosen_branch = 0 if randf() * 100.0 <= (eval(&"probability") as float) else 1

func tick(delta: float) -> Status:
	return tick_condition(delta, _chosen_branch)

func on_end(_status: Status) -> void:
	_chosen_branch = 0

func set_instruction() -> String: return "Chance {probability}%"
func set_node_category() -> String: return "control_flow_node"
func set_input() -> bool: return true
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false
func set_conditions() -> PackedStringArray: return PackedStringArray(["Success ({probability}%)", "Failure"])
