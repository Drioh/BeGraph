@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait For Signal"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits for {signal_name} to be emitted on {node}, returning RUNNING until it fires and SUCCESS afterwards.\n\nFails if {node} can't be resolved or doesn't have that signal."

var _connected_object: Object = null
var _connected_signal: StringName = &""
var _signal_fired: bool = false

func set_instruction() -> String:
	return "Wait for signal {signal_name} on node {node}"

func tick(delta:float) -> Status:
	var target: Object = _resolve_node(get("node"))
	if target == null:
		push_error("\"%s\" non riesce a risolvere il nodo target" % resource_name)
		return Status.FAILURE

	var signal_name : StringName = get("signal_name")
	if signal_name == &"":
		return Status.FAILURE

	if _connected_object != target or _connected_signal != signal_name:
		_disconnect_signal()
		if not target.has_signal(signal_name):
			push_error("\"%s\" non ha il segnale \"%s\"" % [target, signal_name])
			return Status.FAILURE
		_connected_object = target
		_connected_signal = signal_name
		_signal_fired = false
		target.connect(signal_name, _on_signal_fired, CONNECT_ONE_SHOT)

	if _signal_fired:
		_disconnect_signal()
		tick_next(delta)
		return Status.SUCCESS

	return Status.RUNNING

func _on_signal_fired() -> void:
	_signal_fired = true

func _disconnect_signal() -> void:
	if _connected_object != null and is_instance_valid(_connected_object):
		if _connected_object.is_connected(_connected_signal, _on_signal_fired):
			_connected_object.disconnect(_connected_signal, _on_signal_fired)
	_connected_object = null
	_connected_signal = &""

func set_node_category()->String: return "action_node"

func set_input()->bool: return true

func set_output()->bool : return true

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("node", NodePath(""))
	_add_behavior_property("signal_name", &"")
