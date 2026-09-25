@tool
extends GraphEdit
## Read-only, runtime/editor-safe visualization of a [BehaviorGraph]'s execution state, colored by [enum BehaviorNode.Status] (green = SUCCESS, red = FAILURE, amber = RUNNING, gray = idle/never ticked), fading back to idle a short while after a node stops being ticked.[br][br]
## Works in two modes:[br]
## - [b]Same-process[/b] ([method set_graph]): points directly at a live [BehaviorGraph] (e.g. [method BehaviorAgent.get_debug_graph]) and polls it every frame. Used by an in-game debug overlay.[br]
## - [b]Data-driven[/b] ([method build_from_data]/[method apply_status_delta]/[method apply_properties_delta]): built from plain dictionaries with no live resource at all. Used by [BehaviorGraphDebuggerPlugin], since the editor and a running game are different processes and can only exchange serializable data through [EngineDebugger].[br][br]
## Its [GraphNode]s are instances of [BehaviorGraphDebugNode] (a dedicated scene, customizable directly in the editor) rather than plain code-built [GraphNode]s: those depend only on this view's own logic, so the view stays read-only by omission, while still being able to show each node's instruction and (togglable) live behavior property values. Structural edits (new nodes, (dis)connections, deletion) are simply never wired up. Panning, zooming and dragging node positions around still work, harmlessly.
class_name BehaviorGraphDebugView

## Color shown for each [enum BehaviorNode.Status] value while a node has been recently ticked (see [constant FADE_DURATION]).
const STATUS_COLORS : Dictionary = {
	BehaviorNode.Status.SUCCESS: Color(0.376, 0.875, 0.439, 1.0),
	BehaviorNode.Status.FAILURE: Color(1.0, 0.0, 0.235, 1.0),
	BehaviorNode.Status.RUNNING: Color(1.0, 0.875, 0.439, 1.0),
}
## Fallback color used for a node category with no matching [ProjectSettings] entry.
const DEFAULT_IDLE_COLOR : Color = Color(0.5, 0.5, 0.5)
## Seconds it takes a node's status color to fade back to its idle category color after its last tick.
const FADE_DURATION : float = 1.2

## Scene instantiated for each node's visual representation; see [BehaviorGraphDebugNode].
const DEBUG_NODE_SCENE : PackedScene = preload("res://addons/BeGraph/Debug/BehaviorGraphDebugNode.tscn")

## node name (StringName) -> the [BehaviorGraphDebugNode] visualizing it.
var _debug_nodes : Dictionary = {}
## node name (StringName) -> its category (String), cached at build time (needed for the idle color, since data-driven mode has no live resource to ask).
var _node_category : Dictionary = {}
## node category (String) -> {"bg": Color, "border": Color}, cached from [ProjectSettings].
var _category_colors : Dictionary = {}
## node name (StringName) -> {"status": int, "since": int (msec, on whichever clock recorded it)}. Populated either by polling (same-process mode) or by [method apply_status_delta] (data-driven mode); always compared against [method Time.get_ticks_msec] read on that same side, so the two modes never need to share a clock.
var _node_state : Dictionary = {}

## Same-process mode only: node name (StringName) -> the live [BehaviorNode] to poll each frame. Empty in data-driven mode.
var _live_nodes : Dictionary = {}

func _ready() -> void:
	# Structural editing signals (connection_request, disconnection_request, popup_request,
	# delete_nodes_request...) are intentionally never connected: GraphEdit doesn't apply any
	# of those changes on its own, so leaving them unconnected is what keeps this view read-only.
	right_disconnects = false

## Same-process mode: loads a live [param graph], polling its nodes' [member BehaviorNode.last_status]/[member BehaviorNode.last_tick_time]/behavior properties every frame. Pass [code]null[/code] to clear.
func set_graph(graph: BehaviorGraph) -> void:
	_clear()
	if graph == null:
		return
	for behavior_node in graph.nodes.values():
		_add_debug_node_from_info(_info_from_node(behavior_node))
		_live_nodes[StringName(behavior_node.resource_name)] = behavior_node
	for c in graph.connections:
		if _debug_nodes.has(c["from_node"]) and _debug_nodes.has(c["to_node"]):
			connect_node(c["from_node"], c["from_port"], c["to_node"], c["to_port"])

## Data-driven mode: rebuilds the view from [param nodes_data] (an Array of the dictionaries described in [method _add_debug_node_from_info]) and [param connections_data] (an Array of [code]{"from_node","from_port","to_node","to_port"}[/code] dictionaries with String node names) - the shapes [BehaviorGraphDebugBridge] sends over [EngineDebugger]. Call with two empty arrays to clear.
func build_from_data(nodes_data: Array, connections_data: Array) -> void:
	_clear()
	for info in nodes_data:
		_add_debug_node_from_info(info)
	for c in connections_data:
		var from_node : StringName = StringName(c["from_node"])
		var to_node : StringName = StringName(c["to_node"])
		if _debug_nodes.has(from_node) and _debug_nodes.has(to_node):
			connect_node(from_node, c["from_port"], to_node, c["to_port"])

## Data-driven mode: applies a status delta - an Array of [code][node_name:String, status:int][/code] pairs, one entry per node that ticked since the previous update. Anything not listed just keeps fading from wherever it already was. Records "now" ([method Time.get_ticks_msec], read on whichever side calls this) as that node's new freshness reference.
func apply_status_delta(deltas: Array) -> void:
	var now : int = Time.get_ticks_msec()
	for entry in deltas:
		_node_state[StringName(entry[0])] = {"status": entry[1], "since": now}

## Data-driven mode: applies a behavior-properties delta - an Array of [code][node_name:String, properties:Array][/code] pairs (see [method BehaviorGraphDebugBridge._serialize_properties]), one entry per node whose property values changed since the previous update (either because it ticked, or because a blackboard entry it reads from did). Refreshes only the matching [BehaviorGraphDebugNode]'s displayed values.
func apply_properties_delta(deltas: Array) -> void:
	for entry in deltas:
		var gn : BehaviorGraphDebugNode = _debug_nodes.get(StringName(entry[0]))
		if gn:
			gn.update_property_values(entry[1])

func _process(_delta: float) -> void:
	if _live_nodes.size() > 0:
		for key : StringName in _live_nodes.keys():
			var n : BehaviorNode = _live_nodes[key]
			if n.last_tick_time != -1:
				_node_state[key] = {"status": n.last_status, "since": n.last_tick_time}
			var gn : BehaviorGraphDebugNode = _debug_nodes.get(key)
			if gn and not n.behavior_properties.is_empty():
				gn.update_property_values(_serialize_properties(n))
	for key : StringName in _debug_nodes.keys():
		_update_status_visual(key)

#region Building

func _clear() -> void:
	if connections.size() > 0:
		clear_connections()
	for child in get_children().duplicate():
		if child is GraphNode:
			remove_child(child)
			child.queue_free()
	_debug_nodes.clear()
	_node_category.clear()
	_node_state.clear()
	_live_nodes.clear()

## Converts a live [param node] into the plain dictionary shape [method _add_debug_node_from_info] expects: [code]{"name","category","display_name","input","output","position","conditions","instruction","behavior_properties"}[/code], all plain/serializable values - i.e. exactly what [BehaviorGraphDebugBridge] also sends over the wire, so both modes build identical-looking nodes.
func _info_from_node(node: BehaviorNode) -> Dictionary:
	var const_map : Dictionary = node.get_script().get_script_constant_map() if node.get_script() else {}
	var conditions : Array = []
	for c in node.conditions:
		conditions.append(String(c["text"]))
	return {
		"name": String(node.resource_name),
		"category": node.node_category,
		"display_name": const_map.get("DISPLAY_NAME", node.node_category),
		"input": node.input,
		"output": node.output,
		"position": node.position_in_graph,
		"conditions": conditions,
		"instruction": node.instruction,
		"behavior_properties": _serialize_properties(node),
	}

## Reads [param node]'s current behavior property values (resolving blackboard-bound ones through [method BehaviorNode.get], exactly like the node itself does) into the [code]{"name","value","blackboard_key"}[/code] shape used both here and by [method BehaviorGraphDebugBridge._serialize_properties]. Stringifies [Object] values, since those can't be safely displayed/serialized as-is.
func _serialize_properties(node: BehaviorNode) -> Array:
	var ret : Array = []
	for prop in node.behavior_properties:
		var value : Variant = node.get(prop["name"])
		ret.append({
			"name": String(prop["name"]),
			"value": str(value) if value is Object else value,
			"blackboard_key": String(prop["blackboard_key"]),
		})
	return ret

## Instantiates [constant DEBUG_NODE_SCENE] for [param info] and configures it via [method BehaviorGraphDebugNode.setup] - enough to see the graph's shape, its nodes' instructions/properties, and follow its live state.
func _add_debug_node_from_info(info: Dictionary) -> void:
	var key : StringName = StringName(info["name"])

	var gn : BehaviorGraphDebugNode = DEBUG_NODE_SCENE.instantiate()
	gn.name = String(key)
	add_child(gn)
	gn.setup(info)
	gn.position_offset = info.get("position", Vector2.ZERO)

	_node_category[key] = info.get("category", "")
	_apply_category_color(gn, _node_category[key])
	_debug_nodes[key] = gn

## Reads (and caches) the background/border colors this addon already stores in [ProjectSettings] for [param category] - the same ones the editor's own [BehaviorGraphNodeBase] uses - and applies them to [param gn]'s panel/slots.
func _apply_category_color(gn: GraphNode, category: String) -> void:
	if not _category_colors.has(category):
		var setting_key := "BeGraph/colors/node_colors/%s" % category
		if ProjectSettings.has_setting("%s/background_color" % setting_key):
			_category_colors[category] = {
				"bg": ProjectSettings.get_setting("%s/background_color" % setting_key),
				"border": ProjectSettings.get_setting("%s/border_color" % setting_key),
			}
		else:
			_category_colors[category] = {"bg": DEFAULT_IDLE_COLOR, "border": DEFAULT_IDLE_COLOR}

	var colors : Dictionary = _category_colors[category]
	gn.set_indexed("theme_override_styles/panel:bg_color", colors["bg"])
	gn.set_indexed("theme_override_styles/titlebar:bg_color", colors["bg"])
	_set_slot_colors(gn, colors["border"])

#endregion

#region Live status

## Recolors [param node_name]'s [GraphNode]/status label from [member _node_state], fading from the matching [constant STATUS_COLORS] entry back to the node's idle category color over [constant FADE_DURATION] seconds. Since GraphEdit draws each connection line as a gradient between its two endpoints' port colors, recoloring a node's slots is what makes the connections themselves appear to change color with the graph's state.
func _update_status_visual(node_name: StringName) -> void:
	var gn : BehaviorGraphDebugNode = _debug_nodes.get(node_name)
	if gn == null:
		return
	var idle_color : Color = _category_colors.get(_node_category.get(node_name, ""), {}).get("border", DEFAULT_IDLE_COLOR)
	var state = _node_state.get(node_name)

	if state == null:
		_set_slot_colors(gn, idle_color)
		gn.update_status_text("idle")
		gn.status_label.modulate.a = 0.4
		return

	var age : float = (Time.get_ticks_msec() - state["since"]) / 1000.0
	var freshness : float = clamp(1.0 - age / FADE_DURATION, 0.0, 1.0)
	var status_color : Color = STATUS_COLORS.get(state["status"], idle_color)

	_set_slot_colors(gn, idle_color.lerp(status_color, freshness))
	gn.update_status_text(_status_text(state["status"]))
	gn.status_label.modulate.a = 0.4 + 0.6 * freshness

func _status_text(status: int) -> String:
	match status:
		BehaviorNode.Status.SUCCESS: return "SUCCESS"
		BehaviorNode.Status.FAILURE: return "FAILURE"
		BehaviorNode.Status.RUNNING: return "RUNNING"
		_: return "idle"

func _set_slot_colors(gn: GraphNode, color: Color) -> void:
	for slot in gn.get_child_count():
		gn.set("slot/%s/left_color" % slot, color)
		gn.set("slot/%s/right_color" % slot, color)

#endregion
