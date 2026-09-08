@tool
class_name AccessPointNode
extends BehaviorNode

const DISPLAY_NAME : String = "Access Point"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/access_point_node_icon.svg"

func set_instruction() -> String:
	return "Access Point: {label}"

func tick() -> Status:
	if next.size()>0:
		next[0].tick()
	return Status.RUNNING

func set_node_category()->String:return "access_point_node"

func set_input()->bool:return false

func set_output()->bool:return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("label",TYPE_STRING)
