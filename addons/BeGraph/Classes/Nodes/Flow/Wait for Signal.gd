@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait For Signal"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"

var _connected_object: Object = null
var _connected_signal: StringName = &""
var _signal_fired: bool = false

func set_instruction() -> String:
	return "Wait for signal {signal_name} on node {node}"

func tick() -> Status:
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
		return Status.SUCCESS

	return Status.RUNNING

## Accetta sia un [NodePath] assoluto (risolto dalla radice dell'albero di
## scena) sia un riferimento diretto a un [Node] (utile se [param node] è
## collegato a una variabile di blackboard che contiene già il nodo).
func _resolve_node(value: Variant) -> Node:
	if value is Node:
		return value
	if value is NodePath and value != NodePath(""):
		var tree := Engine.get_main_loop() as SceneTree
		if tree == null:
			return null
		return tree.root.get_node_or_null(value)
	return null

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
