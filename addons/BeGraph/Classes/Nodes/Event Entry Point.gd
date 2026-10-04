@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Event Entry Point"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/access_point_node_icon.svg"
const DISPLAY_INFO : String = "Entry point of the graph that waits for {signal_name} to be emitted by {node} and then ticks its successor until it stops returning RUNNING.\n\nLike any access point it can be chosen as a Behavior Agent's starting point (it is listed as 'On <signal_name>'). It doesn't accept incoming connections and always returns RUNNING.\n\nFails if {node} can't be resolved or doesn't have that signal."

## Name shown in the Behavior Agent's starting point list (see [member BehaviorAgent.starting_point]).
var label : String:
	get():
		var s : String = str(get("signal_name"))
		return "On %s" % s if s != "" else "Event (no signal)"

var _target : Object = null
var _callable : Callable
var _fired : bool = false
var _active : bool = false

func set_instruction() -> String:
	return "On signal {signal_name} from {node}"

func tick(delta:float) -> Status:
	if dirty:
		dirty = false
		if not _connect_signal():
			return Status.FAILURE

	if _fired:
		_fired = false
		_active = true

	if _active:
		var status : Status = tick_next(delta)
		if status != Status.RUNNING:
			_active = false
	return Status.RUNNING

func _connect_signal() -> bool:
	var target : Node = _resolve_node(get("node"))
	var signal_name : StringName = get("signal_name")
	if target == null:
		push_error("\"%s\" couldn't resolve node" % resource_name)
		return false
	if not target.has_signal(signal_name):
		push_error("\"%s\": \"%s\" doesn't have signal \"%s\"" % [resource_name, target, signal_name])
		return false

	var arg_count : int = 0
	for s in target.get_signal_list():
		if s["name"] == signal_name:
			arg_count = s["args"].size()
			break

	_callable = _on_signal_fired.unbind(arg_count)
	target.connect(signal_name, _callable)
	_target = target
	return true

func _on_signal_fired() -> void:
	_fired = true

func set_node_category()->String: return "access_point_node"
func set_input()->bool: return false
func set_output()->bool : return true
func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("signal_name", &"")
