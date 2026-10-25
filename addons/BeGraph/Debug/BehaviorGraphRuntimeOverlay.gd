extends CanvasLayer
## Debug overlay usable directly in-game (outside the editor): allows choosing which of the
## currently running BehaviorAgents (BehaviorAgent.DEBUG_GROUP) to inspect, and shows its
## live graph (via BehaviorGraphDebugGraph.set_graph(), "same-process" mode) plus a
## panel of its blackboard.[br]
## To use it: add this scene to the main scene (or register it as an autoload) and press the
## toggle key (default F3, customizable via toggle_action) to show it.[br]
## Note: BehaviorAgent.DEBUG_GROUP is only populated when the game is running (Engine.is_editor_hint()
## is false in that _ready() branch), so this overlay shows nothing while editing
## in the editor: it must be tested by pressing Play.

## Input Map action used to show/hide the overlay. If the action does not yet exist
## in the project, it is created automatically at the first _ready() with the F3 key as default.
@export var toggle_action : StringName = &"begraph_debug_toggle"
## Interval, in seconds, at which the agent list is rechecked (to notice
## new or destroyed agents, for example an enemy dying while being inspected).
@export var agent_refresh_interval : float = 1.0
## Interval, in seconds, at which the selected agent's blackboard is redrawn.
@export var blackboard_refresh_interval : float = 0.25

@onready var root_panel : Control = %RootPanel
@onready var agent_option : OptionButton = %AgentOption
@onready var no_agent_label : Label = %NoAgentLabel
@onready var debug_view : BehaviorGraphDebugGraph = %DebugView
@onready var blackboard_tree : Tree = %BlackboardTree

## The currently inspected agent, or null if none is selected/available.
var _current_agent : BehaviorAgent = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # stays usable even when the game is paused
	root_panel.visible = false

	_ensure_toggle_action()
	_setup_blackboard_tree()
	agent_option.item_selected.connect(_on_agent_selected)

	var agent_timer := Timer.new()
	agent_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	agent_timer.wait_time = agent_refresh_interval
	agent_timer.autostart = true
	agent_timer.timeout.connect(_refresh_agent_list)
	add_child(agent_timer)

	var bb_timer := Timer.new()
	bb_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	bb_timer.wait_time = blackboard_refresh_interval
	bb_timer.autostart = true
	bb_timer.timeout.connect(_refresh_blackboard)
	add_child(bb_timer)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		root_panel.visible = not root_panel.visible
		if root_panel.visible:
			_refresh_agent_list()
		get_viewport().set_input_as_handled()

## Creates begraph_debug_toggle with F3 as default if the project doesn't already define it, so
## the overlay works "out of the box" without manual configuration of the Input Map.
func _ensure_toggle_action() -> void:
	if InputMap.has_action(toggle_action):
		return
	InputMap.add_action(toggle_action)
	var ev := InputEventKey.new()
	ev.keycode = _resolve_toggle_keycode()
	InputMap.action_add_event(toggle_action, ev)

func _setup_blackboard_tree() -> void:
	blackboard_tree.columns = 2
	blackboard_tree.hide_root = true
	blackboard_tree.column_titles_visible = true
	blackboard_tree.set_column_title(0, "Name")
	blackboard_tree.set_column_title(1, "Value")
	blackboard_tree.create_item()

## Rebuilds agent_option starting from BehaviorAgent.DEBUG_GROUP, discarding instances that are no longer
## valid. Calls _select_agent() (which rebuilds the entire graph view) ONLY when the
## selection actually changes, not at every periodic refresh, to avoid losing the view's pan/zoom
## every second.
func _refresh_agent_list() -> void:
	if not root_panel.visible:
		return

	var agents : Array[BehaviorAgent] = []
	for n in get_tree().get_nodes_in_group(BehaviorAgent.DEBUG_GROUP):
		if is_instance_valid(n) and n is BehaviorAgent:
			agents.append(n)

	agent_option.clear()

	if agents.is_empty():
		no_agent_label.visible = true
		debug_view.visible = false
		if _current_agent != null:
			_select_agent(null)
		return

	no_agent_label.visible = false
	debug_view.visible = true

	var reselect_index : int = -1
	for i in agents.size():
		var agent := agents[i]
		agent_option.add_item(_agent_label(agent), i)
		agent_option.set_item_metadata(i, agent)
		if agent == _current_agent:
			reselect_index = i

	if reselect_index != -1:
		agent_option.select(reselect_index) # doesn't emit item_selected: no useless rebuild
	else:
		agent_option.select(0)
		_select_agent(agents[0])

func _agent_label(agent: BehaviorAgent) -> String:
	var info : Dictionary = agent.get_debug_graph_info()
	var graph_name : String = String(info.get("name", ""))
	return "%s (%s)" % [agent.get_path(), graph_name] if graph_name != "" else str(agent.get_path())

func _on_agent_selected(index: int) -> void:
	_select_agent(agent_option.get_item_metadata(index))

func _select_agent(agent: BehaviorAgent) -> void:
	_current_agent = agent
	if agent == null or not is_instance_valid(agent) or agent.get_debug_graph() == null:
		debug_view.set_graph(null)
		blackboard_tree.clear()
		blackboard_tree.create_item()
		return
	debug_view.set_graph(agent.get_debug_graph())
	_refresh_blackboard()

## Redraws the selected agent's blackboard from scratch. Unlike the editor tab
## (which only receives deltas via EngineDebugger, being in a separate process from the game), here
## we are in the same process: we can afford to re-read the entire array at every
## interval without any serialization or network cost.
func _refresh_blackboard() -> void:
	if not root_panel.visible or _current_agent == null or not is_instance_valid(_current_agent):
		return
	var graph : BehaviorGraph = _current_agent.get_debug_graph()
	if graph == null:
		return

	blackboard_tree.clear()
	var root := blackboard_tree.create_item()
	for variable : BlackboardVariable in graph.blackboard:
		if variable == null:
			continue
		var item := blackboard_tree.create_item(root)
		item.set_text(0, String(variable.name))
		item.set_text(1, str(variable.value))

## Reads BeGraph/general_settings/runtime_overlay_toggle_key and converts it to the corresponding Key
## via OS.find_keycode_from_string(), with a silent fallback to F3 if the name is invalid
## or unrecognized (find_keycode_from_string returns KEY_NONE in that case).
func _resolve_toggle_keycode() -> Key:
	var key_name : String = ProjectSettings.get_setting("BeGraph/general_settings/runtime_overlay_toggle_key", "F3")
	if key_name.is_empty():
		return KEY_F3
	var code := OS.find_keycode_from_string(key_name)
	if code == KEY_NONE:
		push_warning("BeGraph: \"%s\" is not a valid key name for runtime_overlay_toggle_key; using F3." % key_name)
		return KEY_F3
	return code
