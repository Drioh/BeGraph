@tool
## Visual [GraphNode] for a generic [BehaviorNode]: renders instruction and conditions as text mixed with inline editors, replacing [code]{placeholder}[/code] tokens.
class_name BehaviorGraphNode
extends BehaviorGraphNodeBase

## Scene instantiated as the inline editor for a single variable (see [method _add_inline_control]).
const BEHAVIOR_GRAPH_NODE_VARIABLE = preload("uid://bup4fdlymdgmo")

@onready var h_flow_container: HFlowContainer = %HFlowContainer
@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var decorator_tree: Tree = %DecoratorTree

var decorator_button: Button
var placeholder_regex := RegEx.new()

#region Decorator UI

const DECORATOR_ROWS: Array[Dictionary] = [
	{"type": "inverter", "label": "Inverter"},
	{"type": "force", "label": "Force", "variant_options": "Success,Failure"},
	{"type": "repeater", "label": "Repeater", "variant_options": "Times,Until Success,Until Failure"},
	{"type": "time_limit", "label": "Time Limiter"},
	{"type": "cooldown", "label": "Cooldown"},
	{"type": "delay", "label": "Delay"},
	{"type": "condition", "label": "Condition"},
]

var _decorator_rows: Dictionary = {}
var _decorator_syncing: bool = false

#endregion

func _on_node_set() -> void:
	if not placeholder_regex.is_valid():
		placeholder_regex.compile("\\{(\\w+)\\}")
		
	tooltip_text = node.instruction
	_render_placeholders(node.instruction, h_flow_container, true)
	
	if node.conditions.size() > 0:
		set_conditions()

	node.conditions_changed.connect(_on_conditions_changed)
	set_node_color("BeGraph/colors/node_colors/%s" % node.node_category)
	
	if node.supports_decorator():
		decorator_button = Button.new()
		decorator_button.flat = true
		decorator_button.toggle_mode = true
		decorator_button.icon = load("res://addons/BeGraph/Icons/star_icon.svg")
		get_titlebar_hbox().add_child(decorator_button)
		get_titlebar_hbox().move_child(decorator_button, -2)
		decorator_button.toggled.connect(func(t): 
			decorator_tree.visible = t
			reset_size.call_deferred()
			)
		_build_decorator_tree()
		node.decorator_changed.connect(_refresh_decorator_tree)

func set_node_script(path: String) -> void:
	if FileAccess.file_exists(path):
		set_node(load(path).new())

func set_conditions() -> void:
	h_box_container.visible = node.conditions.size() > 0
	for condition in node.conditions:
		var container := HFlowContainer.new()
		container.alignment = FlowContainer.ALIGNMENT_END
		add_child(container)
		_render_placeholders(condition.text, container, false)

func _on_conditions_changed() -> void:
	_clear_condition_rows()
	set_conditions()
	set_node_color("BeGraph/colors/node_colors/%s" % node.node_category)
	if graph_edit:
		graph_edit.prune_invalid_connections_from(self)
	reset_size()

func _clear_condition_rows() -> void:
	for child in get_children():
		if child is Control and child != h_flow_container and child != h_box_container:
			remove_child(child)
			child.queue_free()

func _render_placeholders(text: String, container: Control, is_main_instruction: bool) -> void:
	if is_main_instruction:
		for child in container.get_children():
			container.remove_child(child)
			child.queue_free()
	
	var last_end := 0
	for m in placeholder_regex.search_all(text):
		var start := m.get_start()
		var key := m.get_string(1)
		if start > last_end:
			_add_label(text.substr(last_end, start - last_end), container)
		_add_placeholder_value(key, m.get_string(0), container)
		last_end = m.get_end()
		
	if last_end < text.length():
		_add_label(text.substr(last_end, text.length() - last_end), container)

	if not is_main_instruction:
		set_slot_enabled_right(get_child_count() - 1, true)

func _add_placeholder_value(key: String, raw_match: String, container: Control) -> void:
	var variable: Variant = node.get(key)
	if variable == null and not node.get_node_property_info(key, "usage") and PROPERTY_USAGE_NIL_IS_VARIANT:
		push_warning("Value for key \"%s\" is null or property does not exist in node" % key)
		_add_label(raw_match, container, true)
		return

	_add_inline_control(key, variable, container)

func _add_label(segment: String, container: HFlowContainer, is_null: bool = false) -> void:
	if segment.is_empty(): return
	var l := Label.new()
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 16)

	if is_null:
		l.text = "null"
		l.set("theme_override_colors/font_color", ProjectSettings.get_setting("BeGraph/colors/null_variable_color"))
	else:
		l.text = segment

	container.add_child(l)

func _add_inline_control(key: String, value: Variant, container: HFlowContainer) -> void:
	var control: BehaviorGraphNodeVariableEditor = BEHAVIOR_GRAPH_NODE_VARIABLE.instantiate()
	container.add_child(control)
	var associated_property: Dictionary = node.get_node_property_info(key)

	if not control.setup_variable_editor(node, associated_property, graph_edit.current_graph.blackboard):
		push_warning("No available editor for \"%s\" (type %s)" % [key, typeof(value)])
		_add_label("{%s}" % key, container)
		
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	control.resized.connect(reset_size, CONNECT_DEFERRED)

#region Decorator UI

func _build_decorator_tree() -> void:
	decorator_tree.clear()
	decorator_tree.columns = 3
	decorator_tree.hide_root = true
	decorator_tree.column_titles_visible = true
	decorator_tree.set_column_title(0, "")
	decorator_tree.set_column_title(1, "Decorator")
	decorator_tree.set_column_title(2, "Value")
	decorator_tree.set_column_custom_minimum_width(0, 24)
	decorator_tree.set_column_expand(0, false)
	decorator_tree.set_column_expand_ratio(1, 2)
	decorator_tree.set_column_expand_ratio(2, 2)
	
	if not decorator_tree.item_edited.is_connected(_on_decorator_item_edited):
		decorator_tree.item_edited.connect(_on_decorator_item_edited)

	var root := decorator_tree.create_item()
	_decorator_rows.clear()

	for row_info in DECORATOR_ROWS:
		var type: String = row_info["type"]
		var item := decorator_tree.create_item(root)
		item.set_cell_mode(0, TreeItem.CELL_MODE_CHECK)
		item.set_editable(0, true)
		item.set_text(1, row_info["label"])
		item.set_selectable(1, false)
		item.is_any_collapsed()
		item.set_metadata(0, type)
		_decorator_rows[type] = item

		if row_info.has("variant_options"):
			_setup_enum_cell(item, 2, row_info["variant_options"])
			item.set_metadata(2, &"variant")

		match type:
			"repeater":
				_create_range_child(item, "Count / Timeout", &"repeater_count_timeout", 0.0, 1.0)
				_create_range_child(item, "Between Delay (s)", &"between_delay", 0.0, 0.01)
			"time_limit":
				_setup_range_cell(item, 2, &"seconds")
				_create_enum_child(item, "On Timeout", &"on_timeout", "Abort,Let Run")
			"cooldown":
				_setup_range_cell(item, 2, &"seconds")
				_create_enum_child(item, "Mode", &"cooldown_mode", "Always,On Success")
			"delay":
				_setup_range_cell(item, 2, &"seconds")
				_create_enum_child(item, "When", &"delay_mode", "Before,After")
			"condition":
				item.set_selectable(2, false)

	_refresh_decorator_tree()

func _setup_range_cell(item: TreeItem, column: int, meta_key: StringName, min_v: float = 0.0, step: float = 0.01) -> void:
	item.set_editable(column, true)
	item.set_cell_mode(column, TreeItem.CELL_MODE_RANGE)
	item.set_range_config(column, min_v, 100000.0, step)
	item.set_metadata(column, meta_key)

func _create_range_child(parent: TreeItem, label: String, meta_key: StringName, min_v: float = 0.0, step: float = 0.01) -> TreeItem:
	var child := decorator_tree.create_item(parent)
	child.set_text(1, label)
	_setup_range_cell(child, 2, meta_key, min_v, step)
	return child

func _create_enum_child(parent: TreeItem, label: String, meta_key: StringName, options: String) -> TreeItem:
	var child := decorator_tree.create_item(parent)
	child.set_text(1, label)
	_setup_enum_cell(child, 2, options)
	child.set_metadata(2, meta_key)
	return child

func _setup_enum_cell(item: TreeItem, column: int, options_csv: String) -> void:
	item.set_cell_mode(column, TreeItem.CELL_MODE_RANGE)
	item.set_text(column, options_csv)
	item.set_editable(column, true)

func _refresh_decorator_tree() -> void:
	_decorator_syncing = true
	var dec: Dictionary = node.decorator
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
	
	reset_size.call_deferred()
	_decorator_syncing = false

func _on_decorator_item_edited() -> void:
	if _decorator_syncing: return

	var item: TreeItem = decorator_tree.get_edited()
	var column: int = decorator_tree.get_edited_column()

	if column == 0: 
		var type: String = str(item.get_metadata(0))
		if item.is_checked(0):
			node.set_decorator_type(type)
		elif str(node.decorator.get("type", "none")) == type:
			node.set_decorator_type("none")
		_refresh_decorator_tree()
		return

	var field_name = item.get_metadata(column)
	if field_name != null:
		if field_name == &"repeater_count_timeout":
			var variant: int = int(node.decorator.get("variant", 0))
			field_name = &"count" if variant == 0 else &"timeout"
			
		node.set_decorator_field(field_name, item.get_range(column))
		_refresh_decorator_tree()



func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not decorator_tree.visible or str(node.decorator.get("type", "none")) != "condition":
		return false
	if typeof(data) != TYPE_DICTIONARY or not data.has("resource"):
		return false
	if typeof(data["resource"].value) != TYPE_BOOL:
		return false
	return _decorator_condition_cell_at(at_position) != null

func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _decorator_condition_cell_at(at_position) != null:
		node.set_decorator_field(&"blackboard_key", data["resource"].name)

func _decorator_condition_cell_at(at_position: Vector2) -> Variant:
	if not _decorator_rows.has("condition"): return null
	var local: Vector2 = decorator_tree.get_local_mouse_position()
	if not Rect2(Vector2.ZERO, decorator_tree.size).has_point(local): return null
	if decorator_tree.get_item_at_position(local) != _decorator_rows["condition"]: return null
	if decorator_tree.get_column_at_position(local) != 2: return null
	return _decorator_rows["condition"]

#endregion
