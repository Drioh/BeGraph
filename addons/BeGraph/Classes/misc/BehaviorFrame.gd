@tool
## Persistent description of a frame ([GraphFrame]) inside a [BehaviorGraph].
## When [member is_sequence] is [code]false[/code], it only groups other nodes visually and is never ticked.
## When [member is_sequence] is [code]true[/code], it executes its attached nodes in sequence order (with optional [member memory]), returning the sequence's overall [enum BehaviorNode.Status] to the caller of its entry node.
class_name BehaviorFrame
extends BehaviorNode

const DISPLAY_NAME : String = "Frame"
const DISPLAY_ICON : String = "res://addons/BeGraph/Icons/comment_node_icon.svg"
const DISPLAY_INFO : String = "Frame that groups other nodes visually, or executes them as a Sequence when Sequence mode is enabled."

@export var frame_title : String = ""
@export var tint_color : Color = Color(0.28, 0.4, 0.62, 0.7)
## If true the frame shrinks/grows automatically to wrap its attached nodes.
@export var autoshrink : bool = true
@export var frame_size : Vector2 = Vector2(600, 400)
## Names of the nodes attached to this frame.
@export var attached_nodes : Array[StringName] = []
## If true, attached nodes inside this frame are executed sequentially like a Sequence node.
@export var is_sequence : bool = false
## When [member is_sequence] is true, remembers the index of the currently RUNNING node across ticks.
@export var memory : bool = false

var _sequence_nodes : Array[BehaviorNode] = []
var _position : int = 0
var _last_running_idx : int = -1
var _is_ticking_sequence : bool = false

## Computes the deterministic execution order of [member attached_nodes] inside [param graph]:
## follows internal connections starting from the entry node(s) first, falling back to top-to-bottom / left-to-right spatial order.
func compute_sequence_order(graph: BehaviorGraph) -> Array[StringName]:
	var order : Array[StringName] = []
	if graph == null or attached_nodes.is_empty():
		return order

	var in_frame : Dictionary = {} # StringName -> BehaviorNode
	for n_name in attached_nodes:
		var bn : BehaviorNode = graph.nodes.get(n_name, null)
		if bn != null and bn is not BehaviorFrame and bn.node_category != "access_point_node":
			in_frame[n_name] = bn

	if in_frame.is_empty():
		return order

	var internal_next : Dictionary = {} # StringName -> Array[StringName]
	var in_degree : Dictionary = {} # StringName -> int
	var has_external_in : Dictionary = {} # StringName -> bool
	for n_name in in_frame:
		var next_arr : Array[StringName] = []
		internal_next[n_name] = next_arr
		in_degree[n_name] = 0
		has_external_in[n_name] = false

	for c in graph.connections:
		var from_n := StringName(c["from_node"])
		var to_n := StringName(c["to_node"])
		if in_frame.has(from_n) and in_frame.has(to_n):
			var next_arr : Array[StringName] = internal_next[from_n]
			if next_arr.has(to_n): continue
			
			next_arr.append(to_n)
			in_degree[to_n] = int(in_degree[to_n]) + 1
		elif not in_frame.has(from_n) and in_frame.has(to_n):
			has_external_in[to_n] = true

	var sort_spatial := func(a_name: StringName, b_name: StringName) -> bool:
		var a : BehaviorNode = in_frame[a_name]
		var b : BehaviorNode = in_frame[b_name]
		if not is_equal_approx(a.position_in_graph.y, b.position_in_graph.y):
			return a.position_in_graph.y < b.position_in_graph.y
		return a.position_in_graph.x < b.position_in_graph.x

	for n_name in internal_next:
		(internal_next[n_name] as Array[StringName]).sort_custom(sort_spatial)

	var roots : Array[StringName] = []
	for n_name in in_frame:
		if int(in_degree[n_name]) == 0:
			roots.append(n_name)
	roots.sort_custom(func(a_name: StringName, b_name: StringName) -> bool:
		var ext_a : bool = bool(has_external_in[a_name])
		var ext_b : bool = bool(has_external_in[b_name])
		if ext_a != ext_b: return ext_a
		
		return sort_spatial.call(a_name, b_name)
	)

	var visited : Dictionary = {}
	for r in roots:
		_visit_sequence_chain(r, internal_next, visited, order)

	var remaining : Array[StringName] = []
	for n_name in in_frame:
		if visited.has(n_name): continue
		remaining.append(n_name)
	
	remaining.sort_custom(sort_spatial)
	for rem in remaining:
		_visit_sequence_chain(rem, internal_next, visited, order)

	return order

func setup_sequence(graph: BehaviorGraph) -> void:
	_sequence_nodes.clear()
	_position = 0
	_last_running_idx = -1
	_is_ticking_sequence = false
	if not is_sequence or graph == null or attached_nodes.is_empty(): return

	var order : Array[StringName] = compute_sequence_order(graph)
	if order.is_empty(): return

	var in_frame : Dictionary = {}
	for n_name in order:
		in_frame[n_name] = true

	for n_name in order:
		var bn : BehaviorNode = graph.nodes.get(n_name, null)
		if bn == null: continue
		
		_sequence_nodes.append(bn)
		# Strip internal frame targets from _next_ref on linear nodes so BehaviorNode.do_tick()
		# doesn't auto-fire the next node in the frame prematurely; the frame drives them in order.
		if not bn.output or bn.allows_multiple_outputs or not bn.conditions.is_empty(): continue
		
		for i in range(bn._next_ref.size() - 1, -1, -1):
			if not in_frame.has(bn._next_ref[i]): continue
			
			bn._next_ref.remove_at(i)

	if not _sequence_nodes.is_empty():
		_sequence_nodes[0]._sequence_frame_entry = weakref(self)

func _visit_sequence_chain(curr: StringName, internal_next: Dictionary, visited: Dictionary, order: Array[StringName]) -> void:
	if visited.has(curr): return
	
	visited[curr] = true
	order.append(curr)
	for nxt in internal_next[curr]:
		_visit_sequence_chain(nxt, internal_next, visited, order)

func _abort_previous_running(except_idx: int) -> void:
	if _last_running_idx != -1 and _last_running_idx != except_idx and _last_running_idx < _sequence_nodes.size():
		_sequence_nodes[_last_running_idx].abort_running()
	_last_running_idx = -1

func _finish_sequence_tick(status: Status, running_idx: int = -1, next_pos: int = 0) -> Status:
	_last_running_idx = running_idx
	_position = next_pos
	_is_ticking_sequence = false
	last_status = status
	last_tick_time = Time.get_ticks_msec()
	return status

func tick_sequence(delta: float) -> Status:
	var count : int = _sequence_nodes.size()
	if count == 0:
		return Status.SUCCESS

	if not memory or _position >= count:
		_position = 0

	_is_ticking_sequence = true
	var i : int = _position
	while i < count:
		var status : Status = _sequence_nodes[i].do_tick(delta)
		match status:
			Status.RUNNING:
				_abort_previous_running(i)
				return _finish_sequence_tick(Status.RUNNING, i, i if memory else 0)
			Status.FAILURE, Status.ERROR:
				_abort_previous_running(i)
				return _finish_sequence_tick(status)
			Status.SUCCESS:
				if _last_running_idx == i:
					_last_running_idx = -1
		i += 1

	return _finish_sequence_tick(Status.SUCCESS)

func _on_abort_running(visited: Dictionary) -> void:
	_position = 0
	_is_ticking_sequence = false
	if _last_running_idx >= 0 and _last_running_idx < _sequence_nodes.size():
		var running_child : BehaviorNode = _sequence_nodes[_last_running_idx]
		_last_running_idx = -1
		running_child.abort_running(visited)
	else:
		_last_running_idx = -1
		for child in _sequence_nodes:
			child.abort_running(visited)

func set_instruction() -> String: return ""
func tick(delta:float) -> Status: return Status.FAILURE
func set_node_category() -> String: return "frame_node"
func set_input() -> bool: return false
func set_output() -> bool: return false
func set_allows_multiple_outputs() -> bool: return false

## Serializable form of frame, for debug purposes.
func to_debug_info(graph: BehaviorGraph = null) -> Dictionary:
	var g : BehaviorGraph = graph if graph != null else get_graph()
	var seq_order : Array = []
	if is_sequence and g != null:
		seq_order = compute_sequence_order(g).map(func(n): return String(n))
	var attached : Array = []
	for a in attached_nodes:
		attached.append(String(a))
	return {
		"name": String(resource_name),
		"category": "frame_node",
		"display_name": DISPLAY_NAME,
		"title": frame_title,
		"tint_color": tint_color,
		"autoshrink": autoshrink,
		"position": position_in_graph,
		"size": frame_size,
		"attached_nodes": attached,
		"is_sequence": is_sequence,
		"memory": memory,
		"sequence_order": seq_order,
	}
