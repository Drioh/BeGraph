@tool
## Visual [GraphNode] for a generic [BehaviorNode]: renders instruction and conditions as text mixed with inline editors, replacing [code]{placeholder}[/code] tokens.
class_name BehaviorGraphNode
extends BehaviorGraphNodeBase

## Scene instantiated as the inline editor for a single variable (see [method _add_inline_control]).
const BEHAVIOR_GRAPH_NODE_VARIABLE = preload("uid://bup4fdlymdgmo")

@onready var h_flow_container: HFlowContainer = %HFlowContainer
@onready var h_box_container: HBoxContainer = %HBoxContainer
@onready var decorator_tree: BehaviorGraphDecoratorTree = %DecoratorTree
var _condition_drop_overlay : PanelContainer

var decorator_button: Button
var placeholder_regex := RegEx.new()

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
		decorator_tree.setup(node)
		if not node.decorator_changed.is_connected(_update_decorator_button_visual):
			node.decorator_changed.connect(_update_decorator_button_visual)
		_update_decorator_button_visual()

func _update_decorator_button_visual() -> void:
	if decorator_button == null or node == null:
		return
	var dec : Dictionary = node.decorator
	var dec_type : String = String(dec.get("type", "none"))
	var active : bool = (dec_type != "none" and dec_type != "")
	if active:
		var accent : Color = Color(0.4, 0.7, 1.0)
		if Engine.is_editor_hint() and EditorInterface.get_editor_settings():
			accent = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color")
		decorator_button.modulate = accent
		decorator_button.tooltip_text = _format_decorator_summary(dec, dec_type)
	else:
		decorator_button.modulate = Color.WHITE
		decorator_button.tooltip_text = "Configure node decorator (none active)"

func _format_decorator_summary(dec: Dictionary, dec_type: String) -> String:
	match dec_type:
		"inverter":
			return "Active Decorator: Inverter"
		"force":
			var res : String = "Success" if int(dec.get("variant", 0)) == 0 else "Failure"
			return "Active Decorator: Force (%s)" % res
		"repeater":
			var v : int = int(dec.get("variant", 0))
			if v == 0:
				return "Active Decorator: Repeater (%d times)" % int(dec.get("count", 3))
			var mode_str : String = "Until Success" if v == 1 else "Until Failure"
			return "Active Decorator: Repeater (%s)" % mode_str
		"time_limit":
			return "Active Decorator: Time Limiter (%.2fs)" % float(dec.get("seconds", 5.0))
		"cooldown":
			return "Active Decorator: Cooldown (%.2fs)" % float(dec.get("seconds", 2.0))
		"delay":
			var when_str : String = "Before" if int(dec.get("delay_mode", 0)) == 0 else "After"
			return "Active Decorator: Delay (%.2fs, %s)" % [float(dec.get("seconds", 1.0)), when_str]
		"condition":
			var key_str : String = String(dec.get("blackboard_key", &""))
			if key_str == "":
				key_str = "(unbound)"
			var exp_str : String = "True" if int(dec.get("condition_expected", 0)) == 0 else "False"
			return "Active Decorator: Condition (%s == %s)" % [key_str, exp_str]
		_:
			return "Active Decorator: %s" % dec_type

func set_conditions() -> void:
	h_box_container.visible = node.conditions.size() > 0
	# Conditions must land directly after row 1 (h_box_container) - pull decorator_tree out
	# first so it doesn't shift their slot indices, then re-append it last.
	remove_child(decorator_tree)
	for condition in node.conditions:
		var container := HFlowContainer.new()
		container.mouse_filter = Control.MOUSE_FILTER_PASS
		container.alignment = FlowContainer.ALIGNMENT_END
		add_child(container)
		_render_placeholders(condition.text, container, false)
	add_child(decorator_tree)

func _on_conditions_changed() -> void:
	_clear_condition_rows()
	set_conditions()
	set_node_color("BeGraph/colors/node_colors/%s" % node.node_category)
	if graph_edit:
		graph_edit.prune_invalid_connections_from(self)
	reset_size()

func _clear_condition_rows() -> void:
	for child in get_children():
		if !(child is Control and child != h_flow_container and child != h_box_container and child != decorator_tree): continue
		
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
	control.graph_edit = graph_edit
	var associated_property: Dictionary = node.get_node_property_info(key)

	if not control.setup_variable_editor(node, associated_property, graph_edit.current_graph.blackboard):
		push_warning("No available editor for \"%s\" (type %s)" % [key, typeof(value)])
		_add_label("{%s}" % key, container)
		
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.size_flags_vertical = Control.SIZE_EXPAND_FILL
	control.resized.connect(reset_size, CONNECT_DEFERRED)
