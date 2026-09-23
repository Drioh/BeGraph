extends Node
## Runtime bridge that streams live BeGraph execution state to the editor's "BeGraph" debugger tab (see [BehaviorGraphDebuggerPlugin]) via [EngineDebugger]. Auto-registered as an autoload by the BeGraph plugin ([method EditorPlugin.add_autoload_singleton]); does nothing (and disables itself) when no debugger is attached, e.g. an exported build launched normally with no [code]--remote-debug[/code].[br]
## Discovers running [BehaviorAgent]s through [constant BehaviorAgent.DEBUG_GROUP], and for each one: sends its graph's structure once, then periodically sends only the nodes that ticked since the last send (a delta), to keep message traffic light regardless of graph size or agent count.
class_name BehaviorGraphDebugBridge

const MSG_GRAPH : String = "begraph:graph"
const MSG_STATUS : String = "begraph:status"
const MSG_REMOVED : String = "begraph:removed"

## How often (seconds) agents are scanned and status deltas are sent.
@export var broadcast_interval : float = 0.1

## agent path (String) -> true once its graph structure has been sent this session.
var _announced : Dictionary = {}
## agent path (String) -> {node name (StringName): last-broadcast BehaviorNode.last_tick_time}, used to detect which nodes ticked since the previous broadcast.
var _last_sent_tick_time : Dictionary = {}

func _ready() -> void:
	if not EngineDebugger.is_active():
		# No debugger attached (e.g. a normal exported build) - nothing to stream, and no point
		# paying the cost of scanning agents every frame.
		set_process(false)
		return

	var timer := Timer.new()
	timer.wait_time = broadcast_interval
	timer.autostart = true
	timer.timeout.connect(_broadcast)
	add_child(timer)

func _broadcast() -> void:
	var seen_paths : Dictionary = {}

	for agent in get_tree().get_nodes_in_group(BehaviorAgent.DEBUG_GROUP):
		if not agent is BehaviorAgent:
			continue
		var graph : BehaviorGraph = agent.get_debug_graph()
		if graph == null:
			continue

		var path : String = String(agent.get_path())
		seen_paths[path] = true

		if not _announced.has(path):
			_send_graph_structure(path, graph)
			_announced[path] = true
			_last_sent_tick_time[path] = {}

		_send_status_delta(path, graph)

	for path in _announced.keys().duplicate():
		if not seen_paths.has(path):
			EngineDebugger.send_message(MSG_REMOVED, [path])
			_announced.erase(path)
			_last_sent_tick_time.erase(path)

## Sends [param graph]'s full structure (once per agent): every node's name/category/display name/input-output flags/graph position/condition texts, plus the connection list. Matches the dictionary shape [method BehaviorGraphDebugView._add_debug_node_from_info] expects.
func _send_graph_structure(path: String, graph: BehaviorGraph) -> void:
	var nodes_data : Array = []
	for node in graph.nodes.values():
		var const_map : Dictionary = node.get_script().get_script_constant_map() if node.get_script() else {}
		var conditions : Array = []
		for c in node.conditions:
			conditions.append(String(c["text"]))
		nodes_data.append({
			"name": String(node.resource_name),
			"category": node.node_category,
			"display_name": const_map.get("DISPLAY_NAME", node.node_category),
			"input": node.input,
			"output": node.output,
			"position": node.position_in_graph,
			"conditions": conditions,
		})

	var connections_data : Array = []
	for c in graph.connections:
		connections_data.append({
			"from_node": String(c["from_node"]),
			"from_port": c["from_port"],
			"to_node": String(c["to_node"]),
			"to_port": c["to_port"],
		})

	EngineDebugger.send_message(MSG_GRAPH, [path, nodes_data, connections_data])

## Sends only the nodes whose [member BehaviorNode.last_tick_time] changed since the previous broadcast for this agent, as [code][node_name:String, status:int][/code] pairs. Sends nothing at all if no node ticked since last time.
func _send_status_delta(path: String, graph: BehaviorGraph) -> void:
	var last : Dictionary = _last_sent_tick_time[path]
	var deltas : Array = []
	for node in graph.nodes.values():
		if node.last_tick_time == -1:
			continue
		var key : StringName = node.resource_name
		if last.get(key, -1) != node.last_tick_time:
			deltas.append([String(key), node.last_status])
			last[key] = node.last_tick_time

	if deltas.size() > 0:
		EngineDebugger.send_message(MSG_STATUS, [path, deltas])
