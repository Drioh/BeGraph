@tool
extends GraphEdit
## Read-only, runtime/editor-safe visualization of a [BehaviorGraph]'s execution state, colored by [enum BehaviorNode.Status] (green = SUCCESS, red = FAILURE, amber = RUNNING, gray = idle/never ticked), fading back to idle a short while after a node stops being ticked.[br][br]
## Works in two modes:[br]
## - [b]Same-process[/b] ([method set_graph]): points directly at a live [BehaviorGraph] (e.g. [method BehaviorAgent.get_debug_graph]) and polls it every frame. Used by an in-game debug overlay.[br]
## - [b]Data-driven[/b] ([method build_from_data]/[method apply_status_delta]/[method apply_properties_delta]): built from plain dictionaries with no live resource at all. Used by [BehaviorGraphDebuggerPlugin], since the editor and a running game are different processes and can only exchange serializable data through [EngineDebugger].[br][br]
## Its [GraphNode]s are instances of [BehaviorGraphDebugNode] (a dedicated scene, customizable directly in the editor) rather than plain code-built [GraphNode]s: those depend only on this view's own logic, so the view stays read-only by omission, while still being able to show each node's instruction and (togglable) live behavior property values. Structural edits (new nodes, (dis)connections, deletion) are simply never wired up. Panning, zooming and dragging node positions around still work, harmlessly.
class_name BehaviorGraphDebugGraph

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

## node name (StringName) -> number of condition rows it has, cached at build time to know how many slots to color.
var _node_condition_count : Dictionary = {}

## node name (StringName) -> the [BehaviorGraphDebugNode] visualizing it.
var _debug_nodes : Dictionary = {}
## frame name (StringName) -> the [BehaviorGraphDebugFrame] visualizing it.
var _debug_frames : Dictionary = {}
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
	if graph == null: return
	
	for behavior_node in graph.nodes.values():
		if behavior_node is BehaviorFrame: continue
		
		_add_debug_node_from_info(behavior_node.to_debug_info())
		_live_nodes[StringName(behavior_node.resource_name)] = behavior_node

	for behavior_node in graph.nodes.values():
		if behavior_node is not BehaviorFrame: continue
		
		_add_debug_frame_from_info(behavior_node.to_debug_info(graph))
		_live_nodes[StringName(behavior_node.resource_name)] = behavior_node
	
	for c in graph.connections:
		if !_debug_nodes.has(c["from_node"]) or !_debug_nodes.has(c["to_node"]): continue
		
		connect_node(c["from_node"], c["from_port"], c["to_node"], c["to_port"])

## Data-driven mode: rebuilds the view from [param nodes_data] (an Array of the dictionaries described in [method _add_debug_node_from_info]) and [param connections_data] (an Array of [code]{"from_node","from_port","to_node","to_port"}[/code] dictionaries with String node names) - the shapes [BehaviorGraphDebugBridge] sends over [EngineDebugger]. Call with two empty arrays to clear.
func build_from_data(nodes_data: Array, connections_data: Array, frames_data: Array = []) -> void:
	_clear()
	for info in nodes_data:
		_add_debug_node_from_info(info)
	for frame_info in frames_data:
		_add_debug_frame_from_info(frame_info)
	for c in connections_data:
		var from_node : StringName = StringName(c["from_node"])
		var to_node : StringName = StringName(c["to_node"])
		if !_debug_nodes.has(from_node) or !_debug_nodes.has(to_node): continue
		
		connect_node(from_node, c["from_port"], to_node, c["to_port"])

## Data-driven mode: applies a status delta - an Array of [code][node_name:String, status:int][/code] pairs, one entry per node that ticked since the previous update. Anything not listed just keeps fading from wherever it already was. Records "now" ([method Time.get_ticks_msec], read on whichever side calls this) as that node's new freshness reference.
func apply_status_delta(deltas: Array) -> void:
	var now : int = Time.get_ticks_msec()
	for entry in deltas:
		_node_state[StringName(entry[0])] = {
			"status": entry[1],
			"since": now,
			"condition": entry[2] if entry.size() > 2 else -1,
		}

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
				_node_state[key] = {"status": n.last_status, "since": n.last_tick_time, "condition": n.last_ticked_condition}
			var gn : BehaviorGraphDebugNode = _debug_nodes.get(key)
			if gn and n.has_behavior_properties():
				gn.update_property_values(n.serialize_properties())
	
	for key : StringName in _debug_nodes.keys():
		_update_status_visual(key)
	for key : StringName in _debug_frames.keys():
		_update_frame_status_visual(key)

#region Building

func _clear() -> void:
	if connections.size() > 0:
		clear_connections()
	for child in get_children().duplicate():
		if child is not GraphElement: continue
		
		remove_child(child)
		child.queue_free()
	_debug_nodes.clear()
	_debug_frames.clear()
	_node_category.clear()
	_node_condition_count.clear()
	_node_state.clear()
	_live_nodes.clear()

## Instantiates [constant DEBUG_NODE_SCENE] for [param info] and configures it via [method BehaviorGraphDebugNode.setup] - enough to see the graph's shape, its nodes' instructions/properties, and follow its live state.
func _add_debug_node_from_info(info: Dictionary) -> void:
	var key : StringName = StringName(info["name"])

	var gn : BehaviorGraphDebugNode = DEBUG_NODE_SCENE.instantiate()
	gn.name = String(key)
	add_child(gn)
	gn.setup(info)
	gn.position_offset = info.get("position", Vector2.ZERO)
	
	_node_condition_count[key] = (info.get("conditions", []) as Array).size()
	_node_category[key] = info.get("category", "")
	_apply_category_color(gn, _node_category[key])
	_debug_nodes[key] = gn

## Instantiates [BehaviorGraphDebugFrame] for [param info], attaches enclosed nodes, and sets sequence badges.
func _add_debug_frame_from_info(info: Dictionary) -> void:
	var key : StringName = StringName(info["name"])
	var frame := BehaviorGraphDebugFrame.new()
	add_child(frame)
	move_child(frame, 0)
	frame.setup(info)
	_debug_frames[key] = frame

	var attached : Array = info.get("attached_nodes", [])
	for element_name in attached:
		var s_name := StringName(element_name)
		var node_element : BehaviorGraphDebugNode = _debug_nodes.get(s_name, null)
		if node_element == null:
			continue
		attach_graph_element_to_frame(node_element.name, frame.name)
		frame.track(node_element)

	if frame.autoshrink and not attached.is_empty():
		frame.autoshrink_enabled = true

	if info.get("is_sequence", false):
		var seq_order : Array = info.get("sequence_order", [])
		for i in seq_order.size():
			var step_node : BehaviorGraphDebugNode = _debug_nodes.get(StringName(seq_order[i]), null)
			if step_node != null:
				step_node.set_sequence_index(i + 1)

## Reads (and caches) the background/border colors this addon already stores in [ProjectSettings] for [param category] - the same ones the editor's own [BehaviorGraphNodeBase] uses - and applies them to [param gn]'s panel/slots.
func _apply_category_color(gn: GraphNode, category: String) -> void:
	if not _category_colors.has(category):
		var setting_key := "BeGraph/colors/node_colors/%s" % category
		if ProjectSettings.has_setting("%s/background" % setting_key):
			_category_colors[category] = {
				"bg": ProjectSettings.get_setting("%s/background" % setting_key),
				"border": ProjectSettings.get_setting("%s/border" % setting_key),
			}
		else:
			_category_colors[category] = {"bg": DEFAULT_IDLE_COLOR, "border": DEFAULT_IDLE_COLOR}

	var colors : Dictionary = _category_colors[category]
	gn.set_indexed("theme_override_styles/panel:bg_color", colors["bg"])
	gn.set_indexed("theme_override_styles/titlebar:bg_color", colors["bg"])
	
	for slot in gn.get_child_count():
		_set_slot_color(gn, slot, colors["border"])

#endregion

#region Live status

## Recolors [param node_name]'s [GraphNode]/status label from [member _node_state], fading from the matching [constant STATUS_COLORS] entry back to the node's idle category color over [constant FADE_DURATION] seconds. Since GraphEdit draws each connection line as a gradient between its two endpoints' port colors, recoloring a node's slots is what makes the connections themselves appear to change color with the graph's state.
func _update_status_visual(node_name: StringName) -> void:
	var gn : BehaviorGraphDebugNode = _debug_nodes.get(node_name)
	if gn == null: return

	var idle_color : Color = _category_colors.get(_node_category.get(node_name, ""), {}).get("border", DEFAULT_IDLE_COLOR)
	var condition_count : int = _node_condition_count.get(node_name, 0)
	var state = _node_state.get(node_name)

	if state == null:
		_set_slot_color(gn, 0, idle_color)
		for i in condition_count:
			_set_slot_color(gn, 2 + i, idle_color)
		gn.update_status_text("idle")
		gn.status_label.modulate.a = 0.4
		return

	var age : float = (Time.get_ticks_msec() - state["since"]) / 1000.0
	var freshness : float = clamp(1.0 - age / FADE_DURATION, 0.0, 1.0)
	var status_color : Color = STATUS_COLORS.get(state["status"], idle_color)

	_set_slot_color(gn, 0, idle_color.lerp(status_color, freshness))

	if condition_count > 0:
		var taken : int = state.get("condition", -1)
		var traversed_color : Color = STATUS_COLORS[BehaviorNode.Status.SUCCESS]
		var untraversed_color : Color = STATUS_COLORS[BehaviorNode.Status.FAILURE]
		for i in condition_count:
			var target_color : Color = idle_color
			if i == taken:
				target_color = traversed_color
			elif taken != -1:
				target_color = untraversed_color
			_set_slot_color(gn, 2 + i, idle_color.lerp(target_color, freshness))

	gn.update_status_text(_status_text(state["status"]))
	gn.status_label.modulate.a = 0.4 + 0.6 * freshness

func _status_text(status: int) -> String:
	match status:
		BehaviorNode.Status.SUCCESS: return "SUCCESS"
		BehaviorNode.Status.FAILURE: return "FAILURE"
		BehaviorNode.Status.RUNNING: return "RUNNING"
		_: return "idle"

func _set_slot_color(gn: GraphNode, slot: int, color: Color) -> void:
	gn.set("slot/%s/left_color" % slot, color)
	gn.set("slot/%s/right_color" % slot, color)

## Recolors [param frame_name]'s [BehaviorGraphDebugFrame] from [member _node_state], fading from the status color back to its idle tint.
func _update_frame_status_visual(frame_name: StringName) -> void:
	var frame : BehaviorGraphDebugFrame = _debug_frames.get(frame_name)
	if frame == null:
		return
	var state = _node_state.get(frame_name)
	if state == null:
		frame.update_status(frame.idle_tint, 0.0)
		return

	var age : float = (Time.get_ticks_msec() - state["since"]) / 1000.0
	var freshness : float = clamp(1.0 - age / FADE_DURATION, 0.0, 1.0)
	var status_color : Color = STATUS_COLORS.get(state["status"], frame.idle_tint)
	frame.update_status(status_color, freshness)
#endregion
