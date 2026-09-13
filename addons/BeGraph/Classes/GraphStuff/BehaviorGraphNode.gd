@tool
## Visual [GraphNode] for a single [BehaviorNode]: renders its instruction and conditions as text mixed with inline variable editors, replacing [code]{placeholder}[/code] tokens with editable controls.
class_name BehaviorGraphNode
extends GraphNode

## Scene instantiated as the inline editor for a single variable (see [method _add_inline_control]).
const BEHAVIOR_GRAPH_NODE_VARIABLE = preload("uid://bup4fdlymdgmo")

## Holds the rendered instruction (text + inline editors), wrapped to flow across lines.
@onready var h_flow_container: HFlowContainer = %HFlowContainer
## "CONDITIONS" divider row, shown only when there are conditions. The actual condition rows are separate [HFlowContainer]s added directly to this node by [method set_conditions], not children of this container.
@onready var h_box_container: HBoxContainer = %HBoxContainer

## The owning [BehaviorGraphEdit], used to reach its [member BehaviorGraphEdit.current_graph] (e.g. its blackboard, in [method _add_inline_control]).
@export var graph_edit : BehaviorGraphEdit

## The [BehaviorNode] this visual node represents.
var node: BehaviorNode
## Matches [code]{placeholder}[/code] tokens in instruction/condition text.
var placeholder_regex := RegEx.new()

## Loads the [BehaviorNode] script at [param path] (if it exists) and initializes this node from a new instance of it via [method set_node].
func set_node_script(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	set_node(load(path).new())

## Assigns [param n] and configures this [GraphNode] from it: slots from [member BehaviorNode.input]/[member BehaviorNode.output], instruction rendering, conditions, title/position syncing, edit & delete buttons in the titlebar, and category colors.
func set_node(n:BehaviorNode) -> void:
	node = n

	set_slot_enabled_right(0, node.output)
	set_slot_enabled_left(0, node.input)
	
	placeholder_regex.compile("\\{(\\w+)\\}")
	tooltip_text = node.instruction
	
	_render_placeholders(node.instruction, h_flow_container, true)
	if node.conditions.size()>0:
		set_conditions()
		
	var tb : HBoxContainer = get_titlebar_hbox()
	tb.add_theme_constant_override("separation",0)
	tb.get_child(0).add_theme_font_size_override("font_size",18)
	
	title = self.name.validate_node_name()
	node.resource_name = title
	position_offset_changed.connect(func():node.position_in_graph = position_offset)
	
	var edit_button: Button = Button.new()
	edit_button.flat = true
	edit_button.icon = load("res://addons/BeGraph/Icons/edit_icon.svg")
	edit_button.pressed.connect(EditorInterface.edit_resource.bind(node),CONNECT_DEFERRED)
	tb.add_child(edit_button)
	
	tb.add_child(VSeparator.new())
	
	var delete_button: Button = Button.new()
	delete_button.flat = true
	delete_button.icon = load("res://addons/BeGraph/Icons/close_icon.svg")
	delete_button.pressed.connect(delete_request.emit.bind([self.name]),CONNECT_DEFERRED)
	tb.add_child(delete_button)
	
	node.conditions_changed.connect(_on_conditions_changed)
	set_node_color("BeGraph/colors/node_colors/%s" % node.node_category)

## Adds one row per entry in [member BehaviorNode.conditions], showing [member h_box_container] and enabling a right-side slot for each.
func set_conditions() -> void:
	for condition in node.conditions:
		h_box_container.visible = true
		var container :HFlowContainer= HFlowContainer.new()
		container.alignment=FlowContainer.ALIGNMENT_END
		add_child(container)
		_render_placeholders(condition.text, container, false)

## Rebuilds condition rows when [member BehaviorNode.conditions] changes: clears old rows, re-adds them (or hides [member h_box_container] if none), reapplies category colors, prunes now-invalid connections via [member graph_edit], and resizes.
func _on_conditions_changed() -> void:
	_clear_condition_rows()
	if node.conditions.size() > 0:
		set_conditions()
	else:
		h_box_container.visible = false
	set_node_color("BeGraph/colors/node_colors/%s" % node.node_category)
	if graph_edit:
		graph_edit.prune_invalid_connections_from(self)
	reset_size()

## Removes every condition row, keeping only [member h_flow_container] and [member h_box_container].
func _clear_condition_rows() -> void:
	var kept : Array = [h_flow_container, h_box_container]
	for child in get_children().duplicate():
		if child is Control and not kept.has(child):
			remove_child(child)
			child.queue_free()

## Fills [param container] with labels/editors generated from [param text], resolving any [code]{key}[/code] tokens. Enables a right-side slot when [param is_main_instruction] is [code]false[/code] (a condition row).
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
		set_slot_enabled_right(get_child_count()-1,true)
	
## Resolves a single [code]{key}[/code] placeholder to an inline control, or a "null" label (with a warning) if the key is missing from [member node] or its current value is [code]null[/code].
func _add_placeholder_value(key: String, raw_match: String, container: Control) -> void:
	if not node._has(key):
		push_warning("Key \"%s\" not found amongst variables" % key)
		_add_label(raw_match, container,true)
		return

	var variable: Variant = node.get(key)
	if variable == null:
		if ! node.get_node_property_info(key,"usage") and PROPERTY_USAGE_NIL_IS_VARIANT:
			push_warning("Value for key \"%s\" is null" % key)
			_add_label(raw_match, container,true)
			return

	_add_inline_control(key, variable, container)

## Appends a plain [Label] containing [param segment] to [param container]. No-op if [param segment] is empty.[br]
## If [param is_null] is set to [code]true[/code] the label falls back to a "null" red text.
func _add_label(segment: String, container : HFlowContainer, is_null : bool = false) -> void:
	if segment.is_empty():
		return
	var l := Label.new()
	l.mouse_filter =Control.MOUSE_FILTER_PASS
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	l.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size",16)
	
	if is_null:
		l.text = "null"
		l.set("theme_override_colors/font_color",ProjectSettings.get_setting("BeGraph/colors/null_variable_color"))
	else:
		l.text = segment
		
	container.add_child(l)

## Instantiates and sets up a [BehaviorGraphNodeVariableEditor] for [param key]/[param value] in [param container]; falls back to a plain [code]{key}[/code] text label if no editor is available for its type.
func _add_inline_control(key: String, value: Variant,container : HFlowContainer) -> void:
	var type: Variant.Type = typeof(value)
	
	var control: BehaviorGraphNodeVariableEditor = BEHAVIOR_GRAPH_NODE_VARIABLE.instantiate()
	container.add_child(control)
	
	var associated_property : Dictionary = node.get_node_property_info(key)
	
	if not control.setup_variable_editor(node,associated_property,graph_edit.current_graph.blackboard):
		push_warning("No available editor for \"%s\" (type %s)" % [key, type])
		_add_label("{%s}" % key,container)
	
	control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	control.size_flags_vertical=Control.SIZE_EXPAND_FILL
	control.resized.connect(reset_size, CONNECT_DEFERRED)
	return

## Applies the background/border/titlebar colors stored under [ProjectSettings] key [param category] (e.g. [code]"BeGraph/colors/node_colors/action_node"[/code]) to this node's panel, titlebar, and every slot's left/right color.
func set_node_color(category:String):
	var background_color : Color = ProjectSettings.get_setting("%s/background_color"%category)
	var selection_color : Color = ProjectSettings.get_setting("%s/border_color"%category)
	set_indexed("theme_override_styles/panel:bg_color",background_color)
	set_indexed("theme_override_styles/panel_selected:bg_color",background_color)
	set_indexed("theme_override_styles/titlebar:bg_color",background_color)
	set_indexed("theme_override_styles/titlebar_selected:bg_color",background_color)
	
	set_indexed("theme_override_styles/panel_selected:border_color",selection_color)
	set_indexed("theme_override_styles/titlebar_selected:border_color",selection_color)
	for slot in get_child_count():
		set("slot/%s/left_color"%slot,selection_color)
		set("slot/%s/right_color"%slot,selection_color)
