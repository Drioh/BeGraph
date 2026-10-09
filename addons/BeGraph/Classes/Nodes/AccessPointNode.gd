@tool
class_name AccessPointNode
extends BehaviorNode

const DISPLAY_NAME : String = "Access Point"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/access_point_node_icon.svg"
const DISPLAY_SCENE : String = "res://addons/BeGraph/UI/BehaviorGraphAccessPoint.tscn"
const DISPLAY_INFO : String = "Entry point of the graph.\n\nA Behavior Agent starts ticking from the Access Point chosen as its starting point.\n\nAutomatically ticks its single successor every frame; an access point node does not accept incoming connections."

@export_storage var label : String = ""

func tick(delta: float) -> Status:
	if _next_ref.size() > 0:
		tick_next(delta)
	return Status.RUNNING

func set_instruction() -> String: return ""
func set_node_category() -> String: return "access_point_node"
func set_input() -> bool: return false
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
