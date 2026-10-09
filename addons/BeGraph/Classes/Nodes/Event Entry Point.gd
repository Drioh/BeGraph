@tool
extends BehaviorNode

const DISPLAY_NAME : String = "Event Entry Point"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/access_point_node_icon.svg"
const DISPLAY_INFO : String = "Entry point of the graph that waits for {signal_name} to be emitted by {node} and then ticks its successor until it stops returning RUNNING."

@export_custom(BG.HINT_NONE, BG.PROPERTY) var node : NodePath = NodePath("")
@export_custom(BG.HINT_NONE, BG.PROPERTY) var signal_name : StringName = &""

var label : String:
	get():
		var s : String = str(eval(&"signal_name"))
		return "On %s" % s if s != "" else "Event (no signal)"

var _target : Object = null
var _callable : Callable
var _fired : bool = false
var _active : bool = false

func on_start() -> void:
	_target = _resolve_node(eval(&"node"))
	var sig_name : StringName = eval(&"signal_name")
	if _target == null:
		abort("couldn't resolve node")
		return
	if not _target.has_signal(sig_name):
		abort("target node does not have signal '%s'" % sig_name)
		return
	
	var arg_count : int = 0
	for s in _target.get_signal_list():
		if s["name"] == sig_name:
			arg_count = s["args"].size()
			break
	_callable = _on_signal_fired.unbind(arg_count)
	if not _target.is_connected(sig_name, _callable):
		_target.connect(sig_name, _callable)

func tick(delta: float) -> Status:
	if _target == null:
		return Status.FAILURE
		
	if _fired:
		_fired = false
		_active = true
		
	if _active:
		var status : Status = tick_next(delta)
		if status != Status.RUNNING:
			_active = false
			
	return Status.RUNNING

func _on_signal_fired() -> void:
	_fired = true

func on_end(_status: Status) -> void:
	if _target != null and is_instance_valid(_target):
		var sig_name : StringName = eval(&"signal_name")
		if _target.is_connected(sig_name, _callable):
			_target.disconnect(sig_name, _callable)

func set_instruction() -> String: return "On signal {signal_name} from {node}"
func set_node_category() -> String: return "access_point_node"
func set_input() -> bool: return false
func set_output() -> bool: return true
func set_allows_multiple_outputs() -> bool: return false
