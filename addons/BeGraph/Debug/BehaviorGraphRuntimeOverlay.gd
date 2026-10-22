extends CanvasLayer
## Overlay di debug utilizzabile direttamente in game (fuori editor): permette di scegliere, tra
## i BehaviorAgent attualmente in esecuzione (BehaviorAgent.DEBUG_GROUP), quale ispezionare, e ne
## mostra il grafo live (via BehaviorGraphDebugGraph.set_graph(), modalità "same-process") più un
## pannello della sua blackboard.[br]
## Per usarlo: aggiungi questa scena alla scena principale (o registrala come autoload) e premi il
## tasto di toggle (default F3, personalizzabile tramite toggle_action) per mostrarla.[br]
## Nota: BehaviorAgent.DEBUG_GROUP viene popolato solo a gioco avviato (Engine.is_editor_hint()
## è falso in quel branch di _ready()), quindi questo overlay non mostra nulla mentre si edita
## nell'editor: va testato premendo Play.

## Azione dell'Input Map usata per mostrare/nascondere l'overlay. Se l'azione non esiste ancora
## nel progetto, viene creata automaticamente al primo _ready() con il tasto F3 come default.
@export var toggle_action : StringName = &"begraph_debug_toggle"
## Intervallo, in secondi, con cui la lista degli agenti viene ricontrollata (per accorgersi di
## agenti nuovi o distrutti, ad esempio un nemico che muore mentre lo si sta ispezionando).
@export var agent_refresh_interval : float = 1.0
## Intervallo, in secondi, con cui la blackboard dell'agente selezionato viene ridisegnata.
@export var blackboard_refresh_interval : float = 0.25

@onready var root_panel : Control = %RootPanel
@onready var agent_option : OptionButton = %AgentOption
@onready var no_agent_label : Label = %NoAgentLabel
@onready var debug_view : BehaviorGraphDebugGraph = %DebugView
@onready var blackboard_tree : Tree = %BlackboardTree

## L'agente attualmente ispezionato, o null se nessuno è selezionato/disponibile.
var _current_agent : BehaviorAgent = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # resta utilizzabile anche a gioco in pausa
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

## Crea begraph_debug_toggle con F3 come default se il progetto non lo definisce già, così
## l'overlay funziona "out of the box" senza configurazione manuale dell'Input Map.
func _ensure_toggle_action() -> void:
	if InputMap.has_action(toggle_action):
		return
	InputMap.add_action(toggle_action)
	var ev := InputEventKey.new()
	ev.keycode = KEY_F3
	InputMap.action_add_event(toggle_action, ev)

func _setup_blackboard_tree() -> void:
	blackboard_tree.columns = 2
	blackboard_tree.hide_root = true
	blackboard_tree.column_titles_visible = true
	blackboard_tree.set_column_title(0, "Name")
	blackboard_tree.set_column_title(1, "Value")
	blackboard_tree.create_item()

## Ricostruisce agent_option a partire da BehaviorAgent.DEBUG_GROUP, scartando le istanze non più
## valide. Richiama _select_agent() (che ricostruisce l'intera vista del grafo) SOLO quando la
## selezione cambia davvero, non ad ogni refresh periodico, per non perdere pan/zoom della vista
## ogni secondo.
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
		agent_option.select(reselect_index) # non emette item_selected: nessun rebuild inutile
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

## Ridisegna da zero la blackboard dell'agente selezionato. A differenza della tab dell'editor
## (che riceve solo delta via EngineDebugger, essendo in un processo separato dal gioco), qui
## siamo nello stesso processo: possiamo permetterci di rileggere l'intero array ad ogni
## intervallo senza alcun costo di serializzazione o rete.
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
