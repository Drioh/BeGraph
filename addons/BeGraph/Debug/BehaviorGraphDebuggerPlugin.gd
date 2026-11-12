@tool
## Editor-side half of the live graph debugger: receives the messages [BehaviorGraphDebugBridge] sends from the running game via [EngineDebugger], and shows them in a "BeGraph" tab inside the editor's native Debugger bottom panel - one tab per running game session ([method _setup_session]). The tab's UI lives in [constant SESSION_TAB_SCENE] ([BehaviorGraphDebuggerSessionTab]), so its layout can be tweaked directly in the editor instead of by hand-editing this script.[br]
## Registered by [code]BeGraph.gd[/code] via [method EditorPlugin.add_debugger_plugin].
class_name BehaviorGraphDebuggerPlugin
extends EditorDebuggerPlugin

## Scene instantiated once per session by [method _setup_session]; see [BehaviorGraphDebuggerSessionTab].
const SESSION_TAB_SCENE : PackedScene = preload("res://addons/BeGraph/Debug/BehaviorGraphDebuggerSessionTab.tscn")

## session_id -> [code]{"tab": BehaviorGraphDebuggerSessionTab, "agents": Array[String], "graphs": Dictionary, "blackboard": Dictionary, "current_agent": String}[/code]; see [method _setup_session].
var _sessions : Dictionary = {}

var _handlers : Dictionary[String, Callable] = {}

## Returning [code]true[/code] here is what makes the debugger route every [code]"begraph:*"[/code] message to [method _capture].
func _has_capture(prefix: String) -> bool:
	return prefix == BG.Protocol.PREFIX

func _init() -> void:
	_handlers = {
		BG.Protocol.GRAPH: _on_graph_message,
		BG.Protocol.STATUS: _on_status_message,
		BG.Protocol.PROPERTIES: _on_properties_message,
		BG.Protocol.BLACKBOARD: _on_blackboard_message,
		BG.Protocol.REMOVED: _on_removed_message,
	}

func _capture(message: String, data: Array, session_id: int) -> bool:
	if not _sessions.has(session_id) or not _handlers.has(message):
		return false
	_handlers[message].callv([_sessions[session_id]] + data)
	return true

## Called once for every running game session (and again for each new one): instantiates [constant SESSION_TAB_SCENE] and registers it via [method EditorDebuggerSession.add_session_tab].
func _setup_session(session_id: int) -> void:
	var session := get_session(session_id)
	var tab : BehaviorGraphDebuggerSessionTab = SESSION_TAB_SCENE.instantiate()

	_sessions[session_id] = {
		"tab": tab,
		"agents": [], # ordered agent-path Strings, mirrors tab.agent_option's items
		"graphs": {}, # agent path -> [nodes_data, connections_data], so switching agents doesn't need a re-send
		"blackboard": {}, # agent path -> {variable name (String): [type:int, value]}
		"current_agent": "",
	}

	session.add_session_tab(tab)
	tab.agent_option.item_selected.connect(_on_agent_selected.bind(session_id))
	session.stopped.connect(_on_session_stopped.bind(session_id))

## Godot reuses the same [param session_id] (and never calls [method _setup_session] again for it) across multiple Play/stop cycles - only "stopped"/"started" toggle - so [member _sessions] must keep the entry alive here, or [method _capture] would start rejecting every message from the next run as unrecognized. Only the tab's displayed data gets reset, ready for whichever agent reports in next.
func _on_session_stopped(session_id: int) -> void:
	if not _sessions.has(session_id):
		return
	var s : Dictionary = _sessions[session_id]
	s["agents"].clear()
	s["graphs"].clear()
	s["blackboard"].clear()
	s["current_agent"] = ""
	s["tab"].agent_option.clear()
	s["tab"].debug_view.build_from_data([], [], [])
	s["tab"].set_blackboard({})
	s["tab"].running_label.text = "Running: Waiting for a Behavior Agent to report in..."
	s["tab"].graph_label.text = "Graph: Waiting for a Behavior Agent to report in..."

#region Message handling

func _on_graph_message(s: Dictionary, agent_path: String, nodes_data: Array, connections_data: Array, blackboard: Dictionary, graph_name : String, frames_data: Array = []) -> void:
	s["graphs"][agent_path] = [nodes_data, connections_data, frames_data]
	s["blackboard"][agent_path] = blackboard
	s["tab"].graph_label.text = graph_name

	if not s["agents"].has(agent_path):
		s["agents"].append(agent_path)
		s["tab"].agent_option.add_item(agent_path)
		if s["agents"].size() == 1:
			_select_agent(s, agent_path)
	elif s["current_agent"] == agent_path:
		s["tab"].debug_view.build_from_data(nodes_data, connections_data, frames_data)
		s["tab"].set_blackboard(blackboard)

func _on_status_message(s: Dictionary, agent_path: String, deltas: Array) -> void:
	if s["current_agent"] != agent_path:
		return
	s["tab"].debug_view.apply_status_delta(deltas)

	var running : Array = []
	for entry in deltas:
		if entry[1] == BehaviorNode.Status.RUNNING:
			running.append(entry[0])
	if running.size() > 0:
		s["tab"].running_label.text = "Running: %s" % [(running)]

## Forwards a behavior-properties delta (see [method BehaviorGraphDebugBridge._send_properties_delta]) to the currently selected agent's [BehaviorGraphDebugView]; ignored if it belongs to an agent that isn't currently displayed.
func _on_properties_message(s: Dictionary, agent_path: String, deltas: Array) -> void:
	if s["current_agent"] != agent_path:
		return
	s["tab"].debug_view.apply_properties_delta(deltas)

## Merges a blackboard delta (see [method BehaviorGraphDebugBridge._send_blackboard_delta]) into [param agent_path]'s cached snapshot, and forwards it to the blackboard panel if that agent is currently displayed.
func _on_blackboard_message(s: Dictionary, agent_path: String, deltas: Array) -> void:
	var blackboard : Dictionary = s["blackboard"].get(agent_path, {})
	for entry in deltas:
		blackboard[entry[0]] = [entry[1], entry[2]]
	s["blackboard"][agent_path] = blackboard

	if s["current_agent"] == agent_path:
		s["tab"].apply_blackboard_delta(deltas)

func _on_removed_message(s: Dictionary, agent_path: String) -> void:
	var index : int = s["agents"].find(agent_path)
	if index == -1:
		return
	s["agents"].remove_at(index)
	s["tab"].agent_option.remove_item(index)
	s["graphs"].erase(agent_path)
	s["blackboard"].erase(agent_path)
	if s["current_agent"] == agent_path:
		s["current_agent"] = ""
		s["tab"].debug_view.build_from_data([], [], [])
		s["tab"].set_blackboard({})
		s["tab"].running_label.text = ""

func _on_agent_selected(index: int, session_id: int) -> void:
	if not _sessions.has(session_id):
		return
	var s : Dictionary = _sessions[session_id]
	if index < 0 or index >= s["agents"].size():
		return
	_select_agent(s, s["agents"][index])
	

func _select_agent(s: Dictionary, agent_path: String) -> void:
	var index : int = s["agents"].find(agent_path)
	if index == -1:
		return
	s["tab"].agent_option.select(index)
	s["current_agent"] = agent_path
	if s["graphs"].has(agent_path):
		var g : Array = s["graphs"][agent_path]
		var frames : Array = g[2] if g.size() > 2 else []
		s["tab"].debug_view.build_from_data(g[0], g[1], frames)
	s["tab"].set_blackboard(s["blackboard"].get(agent_path, {}))

#endregion
