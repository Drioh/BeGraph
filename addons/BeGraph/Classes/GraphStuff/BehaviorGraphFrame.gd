@tool
## Visual [GraphFrame] bound to a [BehaviorFrame]: editable title, tint color picker and delete button in the titlebar. Deleting it never deletes the attached nodes.
class_name BehaviorGraphFrame
extends GraphFrame

var frame : BehaviorFrame
var graph_edit : BehaviorGraphEdit

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

	_title_edit.text = f.frame_title
	_title_edit.flat = true
	_title_edit.placeholder_text = "Frame Title"
	_title_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_edit.add_theme_font_size_override("font_size", 18)
	_title_edit.text_changed.connect(func(t: String):
		frame.frame_title = t
		title = t)
	tb.add_child(_title_edit)

	_color_button.custom_minimum_size = Vector2(28, 28)
	_color_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL
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

## Makes the frame re-wrap its nodes whenever [param element] changes size (inline editors finish laying out a few frames after a node is created).
func track(element: GraphElement) -> void:
	if not element.resized.is_connected(_refresh_autoshrink):
		element.resized.connect(_refresh_autoshrink, CONNECT_DEFERRED)

func _refresh_autoshrink() -> void:
	if frame == null or not frame.autoshrink:
		return
	autoshrink_enabled = false
	autoshrink_enabled = true
