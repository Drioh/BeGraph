@tool
## Visual [GraphFrame] bound to a [BehaviorFrame]: sequence/memory toggles, editable title, tint color picker and delete button in the titlebar. Deleting it never deletes the attached nodes.
class_name BehaviorGraphFrame
extends GraphFrame

var frame : BehaviorFrame
var graph_edit : BehaviorGraphEdit

var _sequence_check : CheckBox = CheckBox.new()
var _memory_check : CheckBox = CheckBox.new()
var _title_edit : LineEdit = LineEdit.new()
var _color_button : ColorPickerButton = ColorPickerButton.new()

## Must be called after the frame has been added to [param edit] and named.
func set_frame(f: BehaviorFrame, edit: BehaviorGraphEdit) -> void:
	frame = f
	graph_edit = edit

	title = f.frame_title
	position_offset = f.position_in_graph
	size = f.frame_size
	tint_color_enabled = true
	tint_color = f.tint_color
	position_offset_changed.connect(func(): frame.position_in_graph = position_offset)
	resized.connect(func(): frame.frame_size = size)

	var tb : HBoxContainer = get_titlebar_hbox()
	tb.get_child(0).hide() # default title label, replaced by the LineEdit

	_sequence_check.text = "Sequence"
	_sequence_check.tooltip_text = "Execute nodes inside this frame in sequence order"
	_sequence_check.flat = true
	_sequence_check.button_pressed = f.is_sequence
	_sequence_check.toggled.connect(_on_sequence_toggled)
	tb.add_child(_sequence_check)

	_memory_check.text = "Memory"
	_memory_check.tooltip_text = "Remember the currently running node in the sequence across ticks"
	_memory_check.flat = true
	_memory_check.button_pressed = f.memory
	_memory_check.visible = f.is_sequence
	_memory_check.toggled.connect(_on_memory_toggled)
	tb.add_child(_memory_check)

	tb.add_child(VSeparator.new())

	_title_edit.text = f.frame_title
	_title_edit.flat = true
	_title_edit.placeholder_text = "Frame Title"
	_title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_edit.add_theme_font_size_override("font_size", 18)
	_title_edit.text_changed.connect(func(t: String):
		frame.frame_title = t
		title = t)
	tb.add_child(_title_edit)
	
	tb.add_child(VSeparator.new())
	
	_color_button.custom_minimum_size = Vector2(48, 28)
	_color_button.size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	_color_button.flat=true
	_color_button.edit_intensity=false
	_color_button.color = f.tint_color
	_color_button.color_changed.connect(func(c: Color):
		frame.tint_color = c
		tint_color = c)
	tb.add_child(_color_button)

	var delete_button := Button.new()
	var del_array : Array[StringName] = [StringName(name)]
	delete_button.flat = true
	delete_button.icon = load("res://addons/BeGraph/Icons/close_icon.svg")
	delete_button.pressed.connect(graph_edit._on_delete_nodes_request.bind(del_array))
	tb.add_child(delete_button)

func _on_sequence_toggled(toggled: bool) -> void:
	if frame == null or frame.is_sequence == toggled:
		return
	var prev : bool = frame.is_sequence
	set_sequence_enabled(toggled)
	if graph_edit and graph_edit.undo_redo:
		graph_edit.undo_redo.create_action("Toggle Frame Sequence", UndoRedo.MERGE_DISABLE, graph_edit.current_graph)
		graph_edit.undo_redo.add_do_method(self, &"set_sequence_enabled", toggled)
		graph_edit.undo_redo.add_undo_method(self, &"set_sequence_enabled", prev)
		graph_edit.undo_redo.commit_action(false)

func _on_memory_toggled(toggled: bool) -> void:
	if frame == null or frame.memory == toggled:
		return
	var prev : bool = frame.memory
	set_memory_enabled(toggled)
	if graph_edit and graph_edit.undo_redo:
		graph_edit.undo_redo.create_action("Toggle Frame Memory", UndoRedo.MERGE_DISABLE, graph_edit.current_graph)
		graph_edit.undo_redo.add_do_method(self, &"set_memory_enabled", toggled)
		graph_edit.undo_redo.add_undo_method(self, &"set_memory_enabled", prev)
		graph_edit.undo_redo.commit_action(false)

func set_sequence_enabled(enabled: bool) -> void:
	if frame == null:
		return
	frame.is_sequence = enabled
	_sequence_check.set_pressed_no_signal(enabled)
	_memory_check.visible = enabled
	if graph_edit:
		graph_edit._refresh_frame_buttons()

func set_memory_enabled(enabled: bool) -> void:
	if frame == null:
		return
	frame.memory = enabled
	_memory_check.set_pressed_no_signal(enabled)

## Makes the frame re-wrap its nodes whenever [param element] changes size (inline editors finish laying out a few frames after a node is created).
func track(element: GraphElement) -> void:
	if not element.resized.is_connected(_refresh_autoshrink):
		element.resized.connect(_refresh_autoshrink, CONNECT_DEFERRED)

## Counterpart of [method track]: stops reacting to [param element] and re-wraps the remaining nodes.
func untrack(element: GraphElement) -> void:
	if element.resized.is_connected(_refresh_autoshrink):
		element.resized.disconnect(_refresh_autoshrink)
	_refresh_autoshrink.call_deferred()

## Puts the cursor in the title field, ready to type a name.
func focus_title() -> void:
	_title_edit.grab_focus.call_deferred()
	_title_edit.select_all.call_deferred()

func _refresh_autoshrink() -> void:
	if frame == null or not frame.autoshrink:
		return
	autoshrink_enabled = false
	autoshrink_enabled = true
