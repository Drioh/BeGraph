@tool
## Visual [GraphNode] for a [BehaviorComment]: sharp-edged colored box with a TITLE ([LineEdit]) and a COMMENT ([TextEdit]), plus a [ColorPickerButton] in the titlebar bound to [member BehaviorComment.color]. No slots: comments don't connect to anything.
extends BehaviorGraphNodeBase

const COMMENT_COLOR : Color = Color(0.75, 0.536, 0.211, 0.529)

@onready var color_picker: ColorPicker = %ColorPicker
@onready var comment_edit: TextEdit = %CommentEdit

var title_edit: LineEdit = LineEdit.new()
var color_picker_button : Button = Button.new()

func _on_node_set() -> void:
	var comment: BehaviorComment = node
	title_edit.text = comment.comment_title
	comment_edit.text = comment.comment_text
	color_picker.color = comment.color
	resizable=true
	_apply_color(comment.color)
	
	var tb : HBoxContainer = get_titlebar_hbox()

	tb.get_child(0).queue_free()
	
	title_edit.flat=true
	title_edit.placeholder_text="Comment Title"
	title_edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title_edit.add_theme_font_size_override("font_size",18)
	tb.add_child(title_edit)
	title_edit.text_changed.connect(func(t: String): comment.comment_title = t)
	comment_edit.text_changed.connect(func(): comment.comment_text = comment_edit.text)
	
	color_picker_button.custom_minimum_size=Vector2(35,35)
	color_picker_button.pressed.connect(func():
		color_picker.visible=!color_picker.visible
		reset_size.call_deferred()
		)
	color_picker_button.icon=load("res://addons/BeGraph/Icons/color_picker_icon.svg")
	color_picker_button.flat=true
	tb.add_child(color_picker_button)

	color_picker.color_changed.connect(func(c: Color):
		comment.color = c
		_apply_color(c)
	)
	
	tb.move_child(tb.get_child(1),-1)
	reset_size.call_deferred()
	comment.changed.connect(_sync_from_node, CONNECT_DEFERRED)

## Realigns the controls if the resource is modified from the inspector (edit button).
func _sync_from_node() -> void:
	var comment: BehaviorComment = node
	if title_edit.text != comment.comment_title: 
		title_edit.text = comment.comment_title
	if comment_edit.text != comment.comment_text: 
		comment_edit.text = comment.comment_text
	if color_picker.color != comment.color:
		color_picker.color = comment.color
		_apply_color(comment.color)

func _apply_color(c: Color) -> void:
	var border := c.lightened(0.35)
	color_picker_button.self_modulate=c
	set_indexed("theme_override_styles/panel:bg_color", c)
	set_indexed("theme_override_styles/titlebar:bg_color", c)
	set_indexed("theme_override_styles/panel_selected:bg_color", c)
	set_indexed("theme_override_styles/panel_selected:border_color", border)
	set_indexed("theme_override_styles/titlebar_selected:bg_color", c)
	set_indexed("theme_override_styles/titlebar_selected:border_color", border)
