@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Wait For Signal"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/action_node_icon.svg"
const DISPLAY_INFO : String = "Waits until a specific signal is emitted on the target node."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var signal_name : StringName = &""

var _target_obj : Object = null
var _sig_name : StringName = &""
var _fired : bool = false

func on_start() -> void:
	_fired = false
	_target_obj = eval(&"node", true)
	_sig_name = eval(&"signal_name")
	
	if _target_obj == null:
		abort("couldn't resolve target node")
		return
	if _sig_name == &"" or not _target_obj.has_signal(_sig_name):
		abort("target node does not have signal '%s'" % _sig_name)
		return
		
	if not _target_obj.is_connected(_sig_name, _on_signal_fired):
		_target_obj.connect(_sig_name, _on_signal_fired, CONNECT_ONE_SHOT)

func tick(_delta: float) -> Status:
	if _fired:
		return Status.SUCCESS
	return Status.RUNNING

func _on_signal_fired() -> void:
	_fired = true

func on_end(_status: Status) -> void:
	if _target_obj != null and is_instance_valid(_target_obj):
		if _target_obj.is_connected(_sig_name, _on_signal_fired):
			_target_obj.disconnect(_sig_name, _on_signal_fired)
	_target_obj = null

func set_instruction() -> String: return "Wait for signal {signal_name} on node {node}"
func set_node_category() -> String: return "action_node"
func set_input() -> bool: return true
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
