@tool
## Configuration tree for a BehaviorNode's decorators: builds and syncs the rows
## for each decorator type ([constant DECORATOR_ROWS]), applies the changes chosen
## by the user to the assigned [BehaviorNode] (via [method BehaviorNode.set_decorator_type]/
## [method BehaviorNode.set_decorator_field]) and accepts dropping a boolean
## blackboard variable onto the "condition" row to bind it.[br]
## Isolated in a dedicated class (instead of living inside [BehaviorGraphNode]) so that
## its [member Control.mouse_filter] can be set to [constant Control.MOUSE_FILTER_STOP]
## without interfering with the script that builds the node's body: with STOP, a click that the
## Tree does not explicitly handle (e.g., closing an enum popup by clicking outside)
## is absorbed here and doesn't bubble up to the GraphNode, which might otherwise interpret it
## as the start/continuation of dragging the node itself.
class_name BehaviorGraphDecoratorTree
extends Tree

## One entry for each available decorator type, in the order they appear in the tree.
## [code]type[/code] is the value saved in [member BehaviorNode.decorator]["type"]; [code]label[/code]
## is the text shown in column 1; [code]tooltip[/code]/[code]variant_tooltip[/code] are the descriptions
## shown on mouse hover; [code]variant_options[/code], when present, turns the
## 2nd column of the main row into an enum selector instead of a simple checkbox.
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
		Select a boolean variable from the Value column and choose whether it must be True or False in the \"Expected\" row:\n
		while bound and matching the expected value, the action ticks normally; \n
		while bound and not matching, this node returns FAILURE immediately without ticking it. \n
		Unbound, the action always ticks normally."
	},
]

## The BlackboardVariable instance currently bound to the "condition" decorator, tracked by
## reference (not by name): a rename of this exact variable updates the stored key automatically
## instead of unbinding; only its removal from the blackboard, or a value no longer boolean,
## clears the binding.
var _bound_variable : BlackboardVariable = null

## The currently configured [BehaviorNode], assigned via [method setup].
var _node : BehaviorNode
## Decorator type (String) -> the top-level row ([TreeItem]) representing it.
var _decorator_rows: Dictionary = {}
## [code]true[/code] while [method _refresh_decorator_tree] is writing to the tree, to
## prevent [signal Tree.item_edited] (emitted even by changes made in code, not just
## by the user) from being interpreted as a user-made change.
var _decorator_syncing: bool = false

func _ready() -> void:
	if not item_edited.is_connected(_on_decorator_item_edited):
		item_edited.connect(_on_decorator_item_edited)
	if not item_mouse_selected.is_connected(_on_item_mouse_selected):
		item_mouse_selected.connect(_on_item_mouse_selected)

func _exit_tree() -> void:
	_disconnect_blackboard_tracking()

## Associates this Tree with [param n] and (re)builds the entire decorator tree for it.
## Can be called multiple times (e.g., if the same control were reused for
## a different node): disconnects the previous [BehaviorNode], if any, before connecting to the new one.
func setup(n: BehaviorNode) -> void:
	if _node != null and _node != n:
		if _node.decorator_changed.is_connected(_refresh_decorator_tree):
			_node.decorator_changed.disconnect(_refresh_decorator_tree)
		if _node.decorator_changed.is_connected(_sync_bound_variable):
			_node.decorator_changed.disconnect(_sync_bound_variable)
	_disconnect_blackboard_tracking()

	_node = n
	if not _node.decorator_changed.is_connected(_refresh_decorator_tree):
		_node.decorator_changed.connect(_refresh_decorator_tree)
	if not _node.decorator_changed.is_connected(_sync_bound_variable):
		_node.decorator_changed.connect(_sync_bound_variable)

	var graph : BehaviorGraph = _node._graph_ref.get_ref() as BehaviorGraph if _node._graph_ref != null else null
	if graph != null and not graph.changed.is_connected(_on_blackboard_graph_changed):
		graph.changed.connect(_on_blackboard_graph_changed)

	_sync_bound_variable()
	_build_decorator_tree()

## Rebuilds the Tree from scratch: columns, headers, and one row for each entry in
## [constant DECORATOR_ROWS], along with any child rows for type-specific parameters.
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
				_setup_enum_cell(item, 2, "(none)")
				item.set_metadata(2, &"blackboard_key")
				item.set_tooltip_text(2, "Gates the action behind a boolean Blackboard variable, chosen from this dropdown (scanned from the graph's blackboard; only boolean variables are listed).\n(none): the action always ticks normally.\nSelecting a variable: while it matches the \"Expected\" value below, the action ticks normally; otherwise, this node returns FAILURE immediately without ticking it.")
				var expected_child := _create_enum_child(item, "Expected", &"condition_expected", "True,False")
				expected_child.set_tooltip_text(1, "Which boolean value the bound Blackboard variable must have for the action to execute.\nTrue: ticks the action when the variable is true (returns FAILURE when false).\nFalse: ticks the action when the variable is false (returns FAILURE when true).")
				expected_child.set_tooltip_text(2, expected_child.get_tooltip_text(1))
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

## Re-reads [member BehaviorNode.decorator] and updates every row/checkbox/value accordingly,
## without rebuilding the entire tree (it just modifies the items already created by
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
			var item: TreeItem = _decorator_rows["condition"]
			var names : PackedStringArray = _get_boolean_blackboard_names()
			var options : PackedStringArray = PackedStringArray(["(none)"])
			options.append_array(names)
			item.set_text(2, ",".join(options))

			var key : String = str(dec.get("blackboard_key", &""))
			var idx : int = names.find(key)
			item.set_range(2, idx + 1 if idx != -1 else 0)
			item.get_child(0).set_range(2, int(dec.get("condition_expected", 0)))

	_decorator_syncing = false

## Callback for [signal Tree.item_edited]: applies the change just made by the
## user to [member _node] (enabling/disabling a decorator, or changing one of its parameters).
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
	if field_name == null:
		return

	match field_name:
		&"repeater_count_timeout":
			var variant: int = int(_node.decorator.get("variant", 0))
			var resolved_field: StringName = &"count" if variant == 0 else &"timeout"
			_node.set_decorator_field(resolved_field, item.get_range(column))
		&"blackboard_key":
			var idx: int = int(item.get_range(column))
			var names: PackedStringArray = _get_boolean_blackboard_names()
			var key: StringName = &""
			if idx > 0 and idx - 1 < names.size():
				key = StringName(names[idx - 1])
			_node.set_decorator_field(&"blackboard_key", key)
		_:
			_node.set_decorator_field(field_name, item.get_range(column))

	_refresh_decorator_tree()

## Returns the names of every boolean [BlackboardVariable] currently in the graph owning [member _node].
func _get_boolean_blackboard_names() -> PackedStringArray:
	var ret : PackedStringArray = []
	if _node == null or _node._graph_ref == null:
		return ret
	var graph : BehaviorGraph = _node._graph_ref.get_ref() as BehaviorGraph
	if graph == null:
		return ret
	for v : BlackboardVariable in graph.blackboard:
		if v != null and typeof(v.value) == TYPE_BOOL:
			ret.append(String(v.name))
	return ret

## Refreshes the "condition" row's dropdown options right before the user opens it, so the list
## reflects the blackboard's current state even without a live signal connection.
func _on_item_mouse_selected(position: Vector2, _mouse_button_index: int) -> void:
	if not _decorator_rows.has("condition"):return
	
	var item := get_item_at_position(position)
	if item != _decorator_rows["condition"] or get_column_at_position(position) != 2: return
	
	_refresh_condition_options(item)

## Rebuilds only the "condition" row's dropdown text/selection (cheaper than a full _refresh_decorator_tree()).
func _refresh_condition_options(item: TreeItem) -> void:
	var names : PackedStringArray = _get_boolean_blackboard_names()
	var options : PackedStringArray = PackedStringArray(["(none)"])
	options.append_array(names)
	item.set_text(2, ",".join(options))

	var key : String = str(_node.decorator.get("blackboard_key", &""))
	var idx : int = names.find(key)
	item.set_range(2, idx + 1 if idx != -1 else 0)

func _connect_bound_variable(v: BlackboardVariable) -> void:
	if not v.name_changed.is_connected(_on_bound_variable_renamed):
		v.name_changed.connect(_on_bound_variable_renamed)
	if not v.value_changed.is_connected(_on_bound_variable_value_changed):
		v.value_changed.connect(_on_bound_variable_value_changed)

func _disconnect_bound_variable(v: BlackboardVariable) -> void:
	if v.name_changed.is_connected(_on_bound_variable_renamed):
		v.name_changed.disconnect(_on_bound_variable_renamed)
	if v.value_changed.is_connected(_on_bound_variable_value_changed):
		v.value_changed.disconnect(_on_bound_variable_value_changed)

## Resolves (or re-resolves) [member _bound_variable] from [code]_node.decorator.blackboard_key[/code].
## Called whenever the decorator changes (type switch, or a new selection from the dropdown): if
## the currently tracked reference already matches the wanted key by name, nothing is touched -
## this is what lets a rename of that same instance pass through untouched (see
## [method _on_bound_variable_renamed]) instead of forcing a re-lookup every time.
func _sync_bound_variable() -> void:
	var wanted_key : StringName = StringName(_node.decorator.get("blackboard_key", &"")) if _node != null else &""

	if _bound_variable != null and is_instance_valid(_bound_variable) and _bound_variable.name == wanted_key and wanted_key != &"": return

	if _bound_variable != null and is_instance_valid(_bound_variable):
		_disconnect_bound_variable(_bound_variable)
	_bound_variable = null

	if wanted_key == &"" or _node == null or _node._graph_ref == null: return
	
	var graph : BehaviorGraph = _node._graph_ref.get_ref() as BehaviorGraph
	if graph == null:
		return
	for v : BlackboardVariable in graph.blackboard:
		if v != null and v.name == wanted_key:
			_bound_variable = v
			_connect_bound_variable(v)
			break

## The bound variable renamed itself: follow it by updating the stored key to match its new name,
## without unbinding - this is the "by reference" part: the connection to this exact object
## survives the rename.
func _on_bound_variable_renamed(new_name: StringName) -> void:
	if _node == null or str(_node.decorator.get("blackboard_key", &"")) == str(new_name): return
	
	_node.set_decorator_field(&"blackboard_key", new_name)

## The bound variable's value changed: if it's no longer boolean, the binding is no longer valid
## and gets cleared.
func _on_bound_variable_value_changed(new_value: Variant) -> void:
	if typeof(new_value) == TYPE_BOOL: return
	
	if _node != null:
		_node.set_decorator_field(&"blackboard_key", &"")

## Callback for the owning graph's [signal Resource.changed] (emitted when its whole blackboard
## array is reassigned, i.e. a variable was added or removed): if the currently bound variable is
## no longer part of the blackboard, clears the binding.
func _on_blackboard_graph_changed() -> void:
	if _node == null or _node._graph_ref == null: return
	
	if str(_node.decorator.get("type", "none")) == "condition" and _bound_variable != null:
		var graph : BehaviorGraph = _node._graph_ref.get_ref() as BehaviorGraph
		if graph == null or _bound_variable not in graph.blackboard:
			_disconnect_bound_variable(_bound_variable)
			_bound_variable = null
			_node.set_decorator_field(&"blackboard_key", &"")
			return
	_refresh_decorator_tree()

func _disconnect_blackboard_tracking() -> void:
	if _node != null and _node._graph_ref != null:
		var graph : BehaviorGraph = _node._graph_ref.get_ref() as BehaviorGraph
		if graph != null and graph.changed.is_connected(_on_blackboard_graph_changed):
			graph.changed.disconnect(_on_blackboard_graph_changed)
	if _bound_variable != null and is_instance_valid(_bound_variable):
		_disconnect_bound_variable(_bound_variable)
	_bound_variable = null
