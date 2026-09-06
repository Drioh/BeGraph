@tool
## Visual [GraphNode] representation of a single [BehaviorNode] inside a
## [BehaviorGraphEdit]. Renders the node's instruction (and, if present, its
## conditions) as a mix of text labels and inline variable editors, replacing
## any [code]{placeholder}[/code] tokens with the corresponding editable value.
class_name BehaviorGraphNode
extends GraphNode

## Scene used to instantiate an inline editor control for a single
## [BehaviorNode] variable (see [method _add_inline_control]).
const BEHAVIOR_GRAPH_NODE_VARIABLE = preload("uid://bup4fdlymdgmo")

## Container holding the rendered instruction (text labels + inline variable
## editors), wrapped so it can flow across multiple lines.
@onready var h_flow_container: HFlowContainer = %HFlowContainer
## Container holding the condition rows, shown only when
## [member BehaviorNode.conditions] is non-empty.
@onready var h_box_container: HBoxContainer = %HBoxContainer

## The [BehaviorGraphEdit] this node belongs to; used to access shared state
## such as the local/shared blackboards.
@export var graph_edit : BehaviorGraphEdit

## The underlying [BehaviorNode] resource this visual node represents.
var node: BehaviorNode
## Regex used to find [code]{placeholder}[/code] tokens inside instruction and
## condition text.
var placeholder_regex := RegEx.new()

## If [code]false[/code], this node cannot be removed from the graph (see
## [method BehaviorGraphEdit._on_delete_nodes_request]).
@export var can_be_deleted : bool = true

## Loads the [BehaviorNode] script found at [param path] and configures this
## visual node accordingly: sets its color by category, enables/disables the
## input and output slots, renders the instruction (with inline placeholder
## editors), and renders any conditions. Also wires up node
## selection/deselection to switch the editor inspector between the node's
## resource and the parent graph.
func set_node_script(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
		
	set_node(load(path).new())

func set_node(n:BehaviorNode) -> void:
	node = n
	name = node.resource_name
	
	set_node_color("BeGraph/colors/node_colors/%s" % node.node_category)
	set_slot_enabled_right(0, node.output)
	set_slot_enabled_left(0, node.input)
	
	placeholder_regex.compile("\\{(\\w+)\\}")
	tooltip_text = node.instruction
	
	_render_placeholders(node.instruction, h_flow_container, true)
	if node.conditions.size()>0:
		set_conditions()
		
	var tb : HBoxContainer = get_titlebar_hbox()
	tb.add_theme_constant_override("separation",0)
	
	title = self.name
	position_offset_changed.connect(update_node_offset)
	
	var edit_button: Button = Button.new()
	edit_button.flat = true
	edit_button.icon = load("res://addons/BeGraph/Icons/edit_icon.svg")
	edit_button.pressed.connect(EditorInterface.edit_resource.bind(node))
	tb.add_child(edit_button)
	
	var separator = VSeparator.new()
	tb.add_child(separator)
	
	var info_button: Button = Button.new()
	info_button.flat = true
	info_button.icon = load("res://addons/BeGraph/Icons/info_icon.svg")
	info_button.pressed.connect(node.print_node_info)
	tb.add_child(info_button)
	
	var delete_button: Button = Button.new()
	delete_button.flat = true
	delete_button.icon = load("res://addons/BeGraph/Icons/close_icon.svg")
	delete_button.pressed.connect(delete_request.emit.bind([self.name]))
	tb.add_child(delete_button)
	
	
## Renders one row per entry in [member BehaviorNode.conditions]: makes
## [member h_box_container] visible and, for each condition, creates a new
## flow container populated via [method _render_placeholders] and enables a
## dedicated right-side slot for it.
func set_conditions() -> void:
	for condition in node.conditions:
		h_box_container.visible = true
		var container := HFlowContainer.new()
		container.alignment=FlowContainer.ALIGNMENT_END
		add_child(container)
		_render_placeholders(condition.text, container, false)

func update_node_offset():
	node.position_in_graph = position_offset

## Clears (if needed) and fills [param container] with labels/controls generated
## from [param text], replacing any [code]{placeholder}[/code] tokens found via
## [member placeholder_regex]. When [param is_main_instruction] is [code]false[/code]
## (i.e. this is a condition row), also enables the corresponding right-side slot.
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
			_add_text_label(text.substr(last_end, start - last_end), container)
		_add_placeholder_value(key, m.get_string(0), container)
		last_end = m.get_end()
	if last_end < text.length():
		_add_text_label(text.substr(last_end, text.length() - last_end), container)
	
	if not is_main_instruction:
		set_slot_enabled_right(get_child_count()-1,true)

## Resolves a single [code]{key}[/code] placeholder to an inline control, or a
## "null" label (with a warning) if the key is missing from [member node] or
## its current value is [code]null[/code].
func _add_placeholder_value(key: String, raw_match: String, container: Control) -> void:
	if not node._has(key):
		push_warning("Key \"%s\" not found amongst variables" % key)
		_add_null_label(raw_match, container)
		return

	var variable: Variant = node.get(key)
	if variable == null:
		push_warning("Value for key \"%s\" is null" % key)
		_add_null_label(raw_match, container)
		return

	_add_inline_control(key, variable, container)


## Appends a plain [Label] containing [param segment] to [param container].
## Does nothing if [param segment] is empty.
func _add_text_label(segment: String, container : HFlowContainer) -> void:
	if segment.is_empty():
		return
	var l := Label.new()
	l.text = segment
	l.mouse_filter =Control.MOUSE_FILTER_PASS
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	l.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	container.add_child(l)

## Appends a [Label] reading "null" to [param container], with a tooltip
## explaining that the referenced key ([param segment]) was not found. Used as
## a fallback when a placeholder cannot be resolved to a value.
func _add_null_label(segment: String,container : HFlowContainer) -> void:
	if segment.is_empty():
		return
	var l := Label.new()
	l.text = "null"
	l.tooltip_text="Key \"%s\" not found amongst variables" % segment
	l.mouse_filter = Control.MOUSE_FILTER_PASS
	l.set("theme_override_colors/font_color",ProjectSettings.get_setting("BeGraph/colors/null_variable_color"))
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	l.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	l.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	
	container.add_child(l)

## Instantiates a [BehaviorGraphNodeVariableEditor] for [param key]/[param value],
## adds it to [param container], and wires up its blackboard-unlink button and
## resize signal. If no editor is available for the variable's type, falls back
## to a plain [code]{key}[/code] text label instead.
func _add_inline_control(key: String, value: Variant,container : HFlowContainer) -> void:
	var type: Variant.Type = typeof(value)
	
	var control: BehaviorGraphNodeVariableEditor = BEHAVIOR_GRAPH_NODE_VARIABLE.instantiate()
	container.add_child(control)
	
	if not control.setup_variable_editor(node,type,key,graph_edit.local_blackboard,graph_edit.shared_blackboard):
		push_warning("No available editor for \"%s\" (type %s)" % [key, type])
		_add_text_label("{%s}" % key,container)
	
	control.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	control.size_flags_vertical=Control.SIZE_EXPAND_FILL
	control.bb_unlink_button.pressed.connect(node.set_blackboard_reference.bind(key))
	control.resized.connect(reset_size, CONNECT_DEFERRED)
	return

## Applies the background/border/titlebar colors defined in the project
## settings for [param category] (see [code]BeGraph/colors/node_colors/*[/code])
## to this node's panel, titlebar, and slots.
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
		set("slot/%s/left_color",selection_color)
		set("slot/%s/right_color",selection_color)
