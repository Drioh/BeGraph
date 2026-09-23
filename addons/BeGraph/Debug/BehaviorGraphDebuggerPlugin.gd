@tool
## Editor-side half of the live graph debugger: receives the messages [BehaviorGraphDebugBridge] sends from the running game via [EngineDebugger], and shows them in a "BeGraph" tab inside the editor's native Debugger bottom panel - one tab per running game session ([method _setup_session]). The tab's UI lives in [constant SESSION_TAB_SCENE] ([BehaviorGraphDebuggerSessionTab]), so its layout can be tweaked directly in the editor instead of by hand-editing this script.[br]
## Registered by [code]BeGraph.gd[/code] via [method EditorPlugin.add_debugger_plugin].
class_name BehaviorGraphDebuggerPlugin
extends EditorDebuggerPlugin

const MESSAGE_PREFIX : String = "begraph"
const MSG_GRAPH : String = "begraph:graph"
const MSG_STATUS : String = "begraph:status"
const MSG_REMOVED : String = "begraph:removed"

## Scene instantiated once per session by [method _setup_session]; see [BehaviorGraphDebuggerSessionTab].
const SESSION_TAB_SCENE : PackedScene = preload("res://addons/BeGraph/Debug/BehaviorGraphDebuggerSessionTab.tscn")

## session_id -> [code]{"tab": BehaviorGraphDebuggerSessionTab, "agents": Array[String], "graphs": Dictionary, "current_agent": String}[/code]; see [method _setup_session].
var _sessions : Dictionary = {}

## Returning [code]true[/code] here is what makes the debugger route every [code]"begraph:*"[/code] message to [method _capture].
func _has_capture(prefix: String) -> bool:
	return prefix == MESSAGE_PREFIX

func _capture(message: String, data: Array, session_id: int) -> bool:
	if not _sessions.has(session_id):
		return false
	var s : Dictionary = _sessions[session_id]

	if message == MSG_GRAPH:
		_on_graph_message(s, data[0], data[1], data[2])
		return true
	if message == MSG_STATUS:
		_on_status_message(s, data[0], data[1])
		return true
	if message == MSG_REMOVED:
		_on_removed_message(s, data[0])
		return true
	return false

## Called once for every running game session (and again for each new one): instantiates [constant SESSION_TAB_SCENE] and registers it via [method EditorDebuggerSession.add_session_tab].
func _setup_session(session_id: int) -> void:
	var session := get_session(session_id)
	var tab : BehaviorGraphDebuggerSessionTab = SESSION_TAB_SCENE.instantiate()

	_sessions[session_id] = {
		"tab": tab,
		"agents": [], # ordered agent-path Strings, mirrors tab.agent_option's items
		"graphs": {}, # agent path -> [nodes_data, connections_data], so switching agents doesn't need a re-send
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
	s["current_agent"] = ""
	s["tab"].agent_option.clear()
	s["tab"].debug_view.build_from_data([], [])
	s["tab"].agent_label.text = "Waiting for a Behavior Agent to report in..."
	s["tab"].running_label.text = ""

#region Message handling

func _on_graph_message(s: Dictionary, agent_path: String, nodes_data: Array, connections_data: Array) -> void:
	s["graphs"][agent_path] = [nodes_data, connections_data]
	if not s["agents"].has(agent_path):
		s["agents"].append(agent_path)
		s["tab"].agent_option.add_item(agent_path)
		if s["agents"].size() == 1:
			_select_agent(s, agent_path)
	elif s["current_agent"] == agent_path:
		s["tab"].debug_view.build_from_data(nodes_data, connections_data)

func _on_status_message(s: Dictionary, agent_path: String, deltas: Array) -> void:
	if s["current_agent"] != agent_path:
		return
	s["tab"].debug_view.apply_status_delta(deltas)

	var running : Array = []
	for entry in deltas:
		if entry[1] == BehaviorNode.Status.RUNNING:
			running.append(entry[0])
	if running.size() > 0:
		s["tab"].agent_label.text = "Agent: %s" % [agent_path]
		s["tab"].running_label.text = "Running: %s" % [(running)]

func _on_removed_message(s: Dictionary, agent_path: String) -> void:
	var index : int = s["agents"].find(agent_path)
	if index == -1:
		return
	s["agents"].remove_at(index)
	s["tab"].agent_option.remove_item(index)
	s["graphs"].erase(agent_path)
	if s["current_agent"] == agent_path:
		s["current_agent"] = ""
		s["tab"].debug_view.build_from_data([], [])
		s["tab"].agent_label.text = "Agent removed."
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
		s["tab"].debug_view.build_from_data(g[0], g[1])
		s["tab"].agent_label.text = "Agent: %s" % agent_path

#endregion
