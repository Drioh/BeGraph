extends Node
## Runtime bridge that streams live BeGraph execution state to the editor's "BeGraph" debugger tab (see [BehaviorGraphDebuggerPlugin]) via [EngineDebugger]. Auto-registered as an autoload by the BeGraph plugin ([method EditorPlugin.add_autoload_singleton]); does nothing (and disables itself) when no debugger is attached, e.g. an exported build launched normally with no [code]--remote-debug[/code].[br]
## Discovers running [BehaviorAgent]s through [constant BehaviorAgent.DEBUG_GROUP], and for each one: sends its graph's structure (nodes, connections and blackboard) once, then periodically sends only what changed since the last send - ticked nodes' status, changed behavior-property values, and changed blackboard entries - to keep message traffic light regardless of graph size or agent count.
class_name BehaviorGraphDebugBridge

const MSG_GRAPH : String = "begraph:graph"
const MSG_STATUS : String = "begraph:status"
const MSG_PROPERTIES : String = "begraph:properties"
const MSG_BLACKBOARD : String = "begraph:blackboard"
const MSG_REMOVED : String = "begraph:removed"

## How often (seconds) agents are scanned and status/property/blackboard deltas are sent.
@export var broadcast_interval : float = 0.1

## agent path (String) -> true once its graph structure has been sent this session.
var _announced : Dictionary = {}
## agent path (String) -> {node name (StringName): last-broadcast BehaviorNode.last_tick_time}, used to detect which nodes ticked since the previous broadcast.
var _last_sent_tick_time : Dictionary = {}
## agent path (String) -> {node name (StringName): last-broadcast behavior-properties Array (see [method _serialize_properties])}, used to detect which nodes' property values changed since the previous broadcast.
var _last_sent_properties : Dictionary = {}
## agent path (String) -> {variable name (StringName): [type:int, value]}, used to detect which blackboard entries changed since the previous broadcast.
var _last_sent_blackboard : Dictionary = {}

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
			_last_sent_properties[path] = {}
			_last_sent_blackboard[path] = _blackboard_snapshot(graph)

		_send_status_delta(path, graph)
		_send_properties_delta(path, graph)
		_send_blackboard_delta(path, graph)

	for path in _announced.keys().duplicate():
		if not seen_paths.has(path):
			EngineDebugger.send_message(MSG_REMOVED, [path])
			_announced.erase(path)
			_last_sent_tick_time.erase(path)
			_last_sent_properties.erase(path)
			_last_sent_blackboard.erase(path)

## Sends [param graph]'s full structure (once per agent): every node's name/category/display name/input-output flags/graph position/condition texts/instruction/behavior properties, the connection list, and the full blackboard snapshot. Matches the dictionary shape [method BehaviorGraphDebugView._add_debug_node_from_info] expects.
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
			"instruction": node.instruction,
			"behavior_properties": _serialize_properties(node),
		})

	var connections_data : Array = []
	for c in graph.connections:
		connections_data.append({
			"from_node": String(c["from_node"]),
			"from_port": c["from_port"],
			"to_node": String(c["to_node"]),
			"to_port": c["to_port"],
		})

	var blackboard_data : Array = []
	for variable in graph.blackboard:
		blackboard_data.append({
			"name": String(variable.name),
			"type": typeof(variable.value),
			"value": _safe_value(variable.value),
		})

	EngineDebugger.send_message(MSG_GRAPH, [path, nodes_data, connections_data, blackboard_data])

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

## Sends only the nodes whose current behavior-property values differ from the previous broadcast for this agent, as [code][node_name:String, properties:Array][/code] pairs - [param properties] has the shape built by [method _serialize_properties]. Covers both a node ticking with new values and a node's blackboard-bound property changing because some other node wrote to that blackboard entry.
func _send_properties_delta(path: String, graph: BehaviorGraph) -> void:
	var last : Dictionary = _last_sent_properties[path]
	var deltas : Array = []
	for node in graph.nodes.values():
		if node.behavior_properties.is_empty():
			continue
		var current : Array = _serialize_properties(node)
		var key : StringName = node.resource_name
		if last.get(key) != current:
			deltas.append([String(key), current])
			last[key] = current

	if deltas.size() > 0:
		EngineDebugger.send_message(MSG_PROPERTIES, [path, deltas])

## Sends only the blackboard entries whose value changed since the previous broadcast for this agent, as [code][name:String, type:int, value][/code] triples.
func _send_blackboard_delta(path: String, graph: BehaviorGraph) -> void:
	var last : Dictionary = _last_sent_blackboard[path]
	var deltas : Array = []
	for variable in graph.blackboard:
		var current : Array = [typeof(variable.value), _safe_value(variable.value)]
		if last.get(variable.name) != current:
			deltas.append([String(variable.name), current[0], current[1]])
			last[variable.name] = current

	if deltas.size() > 0:
		EngineDebugger.send_message(MSG_BLACKBOARD, [path, deltas])

## Reads [param node]'s current behavior property values (resolving blackboard-bound ones through [method BehaviorNode.get], exactly like the node itself adoes) into a serializable [code]{"name","value","blackboard_key"}[/code] shape.
func _serialize_properties(node: BehaviorNode) -> Array:
	var ret : Array = []
	for prop in node.behavior_properties:
		ret.append({
			"name": String(prop["name"]),
			"type": typeof(node.get(prop["name"])),
			"value": _safe_value(node.get(prop["name"])),
			"blackboard_key": String(prop["blackboard_key"]),
		})
	return ret

## Builds a [code]{variable name (StringName): [type:int, value]}[/code] snapshot of [param graph]'s blackboard, used to seed [member _last_sent_blackboard] right after the full structure (with its own, independently-built blackboard array) has been sent, so the next delta only reports genuinely new changes.
func _blackboard_snapshot(graph: BehaviorGraph) -> Dictionary:
	var ret : Dictionary = {}
	for variable in graph.blackboard:
		ret[variable.name] = [typeof(variable.value), _safe_value(variable.value)]
	return ret

## [EngineDebugger.send_message] can't carry live [Object]/[Node] references across the debugger channel; stringifies [param value] when it's an [Object] so it's still shown as something readable instead of failing to serialize.
func _safe_value(value: Variant) -> Variant:
	if value is Object:
		return str(value)
	return value
