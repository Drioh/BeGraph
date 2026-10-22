@tool
## Albero di configurazione dei decorator per un BehaviorNode: costruisce e sincronizza le righe
## per ciascun tipo di decorator ([constant DECORATOR_ROWS]), applica le modifiche scelte
## dall'utente al [BehaviorNode] assegnato (tramite [method BehaviorNode.set_decorator_type]/
## [method BehaviorNode.set_decorator_field]) e accetta il trascinamento di una variabile
## booleana di blackboard sulla riga "condition" per collegarla.[br]
## Isolato in una classe dedicata (anziché vivere dentro [BehaviorGraphNode]) in modo che il
## suo [member Control.mouse_filter] possa essere impostato a [constant Control.MOUSE_FILTER_STOP]
## senza interferire con lo script che costruisce il corpo del nodo: con STOP, un click che la
## Tree non gestisce esplicitamente (ad esempio la chiusura di un popup enum cliccando fuori)
## viene assorbito qui e non risale più al GraphNode, che altrimenti potrebbe interpretarlo
## come inizio/continuazione di un trascinamento del nodo stesso.
class_name BehaviorGraphDecoratorTree
extends Tree

## Una voce per ciascun tipo di decorator disponibile, nell'ordine in cui compaiono nell'albero.
## [code]type[/code] è il valore salvato in [member BehaviorNode.decorator]["type"]; [code]label[/code]
## il testo mostrato in colonna 1; [code]tooltip[/code]/[code]variant_tooltip[/code] le descrizioni
## mostrate al passaggio del mouse; [code]variant_options[/code], quando presente, rende la
## colonna 2 della riga principale un selettore enum invece di un semplice checkbox.
const DECORATOR_ROWS: Array[Dictionary] = [
	{
		"type": "inverter",
		"label": "Inverter",
		"tooltip": "Ticks the node's own action and swaps its outcome:\n
		SUCCESS becomes FAILURE and FAILURE becomes SUCCESS.\n
		RUNNING and ERROR are returned unchanged."
	},
	{
		"type": "force",
		"label": "Force",
		"variant_options": "Success,Failure",
		"tooltip": "Repleaces this node real outcome with the fixed result chosen in the Value column.\n
		ERROR is left untouched, since it signals a genuine abort rather than a normal outcome.",
		"variant_tooltip": "Which fixed result to report once the action finishes.\n
		Success: always reports SUCCESS. \n
		Failure: always reports FAILURE. \n
		Has no effect while the action is RUNNING or if it returns ERROR."
	},
	{
		"type": "repeater",
		"label": "Repeater",
		"variant_options": "Times,Until Success,Until Failure",
		"tooltip": "Reruns the action attempt after attempt instead of ticking it only once.\n
		Use the child rows below to control how many attempts are made (or for how long it keeps retrying) and how long to wait between attempts.\n\n
		Note: a node using this decorator should have no outgoing connection of its own, since the action's own successor fires on every single attempt.",
		"variant_tooltip": "Times: repeats a fixed number of attempts, read from \"Count / Timeout\" below (0 = unlimited).\n
		Until Success: keeps retrying until the action returns SUCCESS, or gives up as FAILURE once the optional timeout elapses.\n
		Until Failure: keeps retrying until the action returns FAILURE, or gives up as FAILURE once the optional timeout elapses."
	},
	{
		"type": "time_limit",
		"label": "Time Limiter",
		"tooltip": "Forces FAILURE outcome if this node is still RUNNING\n
		once the number of seconds in the Value column has elapsed."
	},
	{
		"type": "cooldown",
		"label": "Cooldown",
		"tooltip": "Once the action finishes, makes this node return FAILURE immediately - without even \n
		ticking the action - for the number of seconds set in the Value column."
	},
	{
		"type": "delay",
		"label": "Delay",
		"tooltip": "Adds a pause of the duration set in the Value column, \n
		either before the action starts ticking for the first time, \n
		or after it finishes but before its result is actually reported (see the \"When\" row below)."
	},
	{
		"type": "condition",
		"label": "Condition",
		"tooltip": "Gates the action behind a boolean Blackboard variable. \n
		Drag a boolean variable from the blackboard panel onto the Value column to bind it:\n
		while bound and true, the action ticks normally; \n
		while bound and false, this node returns FAILURE immediately without ticking it. \n
		Unbound, the action always ticks normally."
	},
]

## Il [BehaviorNode] attualmente configurato, assegnato tramite [method setup].
var _node : BehaviorNode
## Tipo di decorator (String) -> la riga di primo livello ([TreeItem]) che lo rappresenta.
var _decorator_rows: Dictionary = {}
## [code]true[/code] mentre [method _refresh_decorator_tree] sta scrivendo nell'albero, per
## evitare che [signal Tree.item_edited] (emesso anche da modifiche fatte in codice, non solo
## dall'utente) venga interpretato come una modifica proveniente dall'utente.
var _decorator_syncing: bool = false

func _ready() -> void:
	if not item_edited.is_connected(_on_decorator_item_edited):
		item_edited.connect(_on_decorator_item_edited)

## Associa questa Tree a [param n] e (ri)costruisce l'intero albero dei decorator per lui.
## Può essere richiamato più volte (ad esempio se lo stesso controllo venisse riutilizzato per
## un nodo diverso): scollega il precedente [BehaviorNode], se presente, prima di collegarsi al nuovo.
func setup(n: BehaviorNode) -> void:
	if _node != null and _node != n and _node.decorator_changed.is_connected(_refresh_decorator_tree):
		_node.decorator_changed.disconnect(_refresh_decorator_tree)

	_node = n
	if not _node.decorator_changed.is_connected(_refresh_decorator_tree):
		_node.decorator_changed.connect(_refresh_decorator_tree)

	_build_decorator_tree()

## Ricostruisce da zero la Tree: colonne, intestazioni e una riga per ciascuna voce di
## [constant DECORATOR_ROWS], con le eventuali righe figlie dei parametri specifici del tipo.
func _build_decorator_tree() -> void:
	clear()
	columns = 3
	hide_root = true
	column_titles_visible = true
	set_column_title(0, "")
	set_column_title(1, "Decorator")
	set_column_title(2, "Value")
	set_column_custom_minimum_width(0, 24)
	set_column_expand(0, false)
	set_column_expand_ratio(1, 2)
	set_column_expand_ratio(2, 2)

	var root := create_item()
	_decorator_rows.clear()

	for row_info in DECORATOR_ROWS:
		var type: String = row_info["type"]
		var item := create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_text(1, row_info["label"])
		item.set_selectable(1, false)
		item.set_metadata(0, type)
		_decorator_rows[type] = item

		var desc : String = row_info.get("tooltip", "")
		item.set_tooltip_text(0, "Enable the \"%s\" decorator for this node. Only one decorator can be active at a time; checking this box disables whichever other decorator was previously selected.\n\n%s" % [row_info["label"], desc])
		item.set_tooltip_text(1, desc)

		if row_info.has("variant_options"):
			_setup_enum_cell(item, 2, row_info["variant_options"])
			item.set_metadata(2, &"variant")
			item.set_tooltip_text(2, row_info.get("variant_tooltip", desc))
		elif desc != "":
			item.set_tooltip_text(2, desc)

		match type:
			"repeater":
				var count_child := _create_range_child(item, "Count / Timeout", &"repeater_count_timeout", 0.0, 1.0)
				count_child.set_tooltip_text(1, "In \"Times\" mode: number of attempts before stopping (0 = infinite). In \"Until Success\" / \"Until Failure\" mode: seconds to keep retrying before giving up as FAILURE (0 = no timeout, retries forever).")
				count_child.set_tooltip_text(2, count_child.get_tooltip_text(1))
				var delay_child := _create_range_child(item, "Between Delay (s)", &"between_delay", 0.0, 0.01)
				delay_child.set_tooltip_text(1, "Seconds to wait, doing nothing, between the end of one attempt and the start of the next. 0 = start the next attempt immediately.")
				delay_child.set_tooltip_text(2, delay_child.get_tooltip_text(1))
			"time_limit":
				_setup_range_cell(item, 2, &"seconds")
				item.set_tooltip_text(2, "Maximum number of seconds the action may keep running before this decorator forces a FAILURE. 0 (or negative) disables the limit.")
				var timeout_child := _create_enum_child(item, "On Timeout", &"on_timeout", "Abort,Let Run")
				timeout_child.set_tooltip_text(1, "What happens to the action's internal state when the time limit is hit. Abort: fully resets the action, so on_start() runs again from scratch next time. Let Run: leaves the action's internal state untouched, so it can resume where it left off (e.g. an in-progress Tween).")
				timeout_child.set_tooltip_text(2, timeout_child.get_tooltip_text(1))
			"cooldown":
				_setup_range_cell(item, 2, &"seconds")
				item.set_tooltip_text(2, "How many seconds this node stays on cooldown (returning FAILURE immediately, without ticking the action) after it finishes.")
				var mode_child := _create_enum_child(item, "Mode", &"cooldown_mode", "Always,On Success")
				mode_child.set_tooltip_text(1, "Always: starts the cooldown regardless of how the action finished. On Success: only starts the cooldown if the action finished with SUCCESS; a FAILURE does not trigger it.")
				mode_child.set_tooltip_text(2, mode_child.get_tooltip_text(1))
			"delay":
				_setup_range_cell(item, 2, &"seconds")
				item.set_tooltip_text(2, "Length of the pause, in seconds.")
				var when_child := _create_enum_child(item, "When", &"delay_mode", "Before,After")
				when_child.set_tooltip_text(1, "Before: waits the configured seconds (returning RUNNING) before ticking the action for the first time. After: ticks the action right away, but once it returns a final SUCCESS/FAILURE, holds that result back for the configured seconds before reporting it.")
				when_child.set_tooltip_text(2, when_child.get_tooltip_text(1))
			"condition":
				item.set_selectable(2, false)
				item.set_tooltip_text(2, "Drop a boolean Blackboard variable here to bind it. Until a variable is bound, this decorator has no effect and the action ticks as usual.")

	_refresh_decorator_tree()

func _setup_range_cell(item: TreeItem, column: int, meta_key: StringName, min_v: float = 0.0, step: float = 0.01) -> void:
	item.set_editable(column, true)
	item.set_cell_mode(column, TreeItem.CELL_MODE_RANGE)
	item.set_range_config(column, min_v, 100000.0, step)
	item.set_metadata(column, meta_key)

func _create_range_child(parent: TreeItem, label: String, meta_key: StringName, min_v: float = 0.0, step: float = 0.01) -> TreeItem:
	var child := create_item(parent)
	child.set_text(1, label)
	_setup_range_cell(child, 2, meta_key, min_v, step)
	return child

func _create_enum_child(parent: TreeItem, label: String, meta_key: StringName, options: String) -> TreeItem:
	var child := create_item(parent)
	child.set_text(1, label)
	_setup_enum_cell(child, 2, options)
	child.set_metadata(2, meta_key)
	return child

func _setup_enum_cell(item: TreeItem, column: int, options_csv: String) -> void:
	item.set_cell_mode(column, TreeItem.CELL_MODE_RANGE)
	item.set_text(column, options_csv)
	item.set_editable(column, true)

## Rilegge [member BehaviorNode.decorator] e aggiorna ogni riga/checkbox/valore di conseguenza,
## senza ricostruire l'intero albero (si limita a modificare gli item già creati da
## [method _build_decorator_tree]).
func _refresh_decorator_tree() -> void:
	_decorator_syncing = true
	var dec: Dictionary = _node.decorator
	var current_type: String = str(dec.get("type", "none"))

	for type in _decorator_rows:
		var item: TreeItem = _decorator_rows[type]
		item.set_checked(0, type == current_type)

	match current_type:
		"force":
			_decorator_rows["force"].set_range(2, int(dec.get("variant", 0)))
		"repeater":
			var item: TreeItem = _decorator_rows["repeater"]
			var variant: int = int(dec.get("variant", 0))
			item.set_range(2, variant)
			item.get_child(0).set_text(1, "Count (0 = inf)" if variant == 0 else "Timeout (0 = inf)")
			item.get_child(0).set_range(2, dec.get("count", 3) if variant == 0 else dec.get("timeout", 0.0))
			item.get_child(1).set_range(2, dec.get("between_delay", 0.0))
		"time_limit":
			var item: TreeItem = _decorator_rows["time_limit"]
			item.set_range(2, dec.get("seconds", 5.0))
			item.get_child(0).set_range(2, int(dec.get("on_timeout", 0)))
		"cooldown":
			var item: TreeItem = _decorator_rows["cooldown"]
			item.set_range(2, dec.get("seconds", 2.0))
			item.get_child(0).set_range(2, int(dec.get("cooldown_mode", 0)))
		"delay":
			var item: TreeItem = _decorator_rows["delay"]
			item.set_range(2, dec.get("seconds", 1.0))
			item.get_child(0).set_range(2, int(dec.get("delay_mode", 0)))
		"condition":
			var key: String = str(dec.get("blackboard_key", &""))
			_decorator_rows["condition"].set_text(2, key if key != "" else "(drop a bool variable)")

	_decorator_syncing = false

## Callback per [signal Tree.item_edited]: applica a [member _node] la modifica appena fatta
## dall'utente (attivazione/disattivazione di un decorator, o cambio di uno dei suoi parametri).
func _on_decorator_item_edited() -> void:
	if _decorator_syncing: return

	var item: TreeItem = get_edited()
	var column: int = get_edited_column()

	if column == 0:
		var type: String = str(item.get_metadata(0))
		if item.is_checked(0):
			_node.set_decorator_type(type)
		elif str(_node.decorator.get("type", "none")) == type:
			_node.set_decorator_type("none")
		_refresh_decorator_tree()
		return

	var field_name = item.get_metadata(column)
	if field_name != null:
		if field_name == &"repeater_count_timeout":
			var variant: int = int(_node.decorator.get("variant", 0))
			field_name = &"count" if variant == 0 else &"timeout"

		_node.set_decorator_field(field_name, item.get_range(column))
		_refresh_decorator_tree()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not visible or _node == null or str(_node.decorator.get("type", "none")) != "condition":
		return false
	if typeof(data) != TYPE_DICTIONARY or not data.has("resource"):
		return false
	if typeof(data["resource"].value) != TYPE_BOOL:
		return false
	return _condition_cell_at(at_position) != null

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _condition_cell_at(at_position) != null:
		_node.set_decorator_field(&"blackboard_key", data["resource"].name)

## Restituisce la riga "condition" se [param at_position] (coordinate locali a questa Tree,
## già fornite come tali da Godot a [method _can_drop_data]/[method _drop_data]) cade esattamente
## sulla sua colonna 2 ("Value"), altrimenti [code]null[/code].
func _condition_cell_at(at_position: Vector2) -> Variant:
	if not _decorator_rows.has("condition"): return null
	if not Rect2(Vector2.ZERO, size).has_point(at_position): return null
	if get_item_at_position(at_position) != _decorator_rows["condition"]: return null
	if get_column_at_position(at_position) != 2: return null
	return _decorator_rows["condition"]
