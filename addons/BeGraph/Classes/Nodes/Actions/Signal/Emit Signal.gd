@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Emit Signal"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Emits the owning Behavior Agent's behavior_agent_signal, passing {args} as payload.\n\nAlways succeeds; fails only if the agent can't be found."

var agent : BehaviorAgent 
func set_instruction() -> String:
	return "Emit agent signal with {args}"

func tick(delta:float) -> Status:
	if dirty:
		agent= get_agent()
	dirty=false
	if agent == null:
		push_error("\"%s\" couldn't find the BehaviorAgent" % resource_name)
		return Status.FAILURE

	agent.behavior_signal.emit(get("args"))
	tick_next(delta)
	return Status.SUCCESS

func set_node_category()->String: return "action_node"
func set_input()->bool: return true
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("args", [])
