@tool
## Visual [GraphNode] for a [BehaviorComment]: sharp-edged colored box with a TITLE ([LineEdit]) and a COMMENT ([TextEdit]), plus a [ColorPickerButton] in the titlebar bound to [member BehaviorComment.color]. No slots: comments don't connect to anything.
extends BehaviorGraphNodeBase

@onready var comment_edit: TextEdit = %CommentEdit

var title_edit: LineEdit = LineEdit.new()
var color_picker_button : ColorPickerButton = ColorPickerButton.new()

func _on_node_set() -> void:
	var comment: BehaviorComment = node
	title_edit.text = comment.comment_title
	comment_edit.text = comment.comment_text
	
	resizable=true
	resize_end.connect(func(p):
		comment.node_size=size
		)
	
	_apply_color(comment.background_color,comment.border_color)
	
	var tb : HBoxContainer = get_titlebar_hbox()

	tb.get_child(0).queue_free()
	
	title_edit.flat=true
	title_edit.placeholder_text="Comment Title"
	title_edit.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	title_edit.add_theme_font_size_override("font_size",18)
	tb.add_child(title_edit)
	title_edit.text_changed.connect(func(t: String): comment.comment_title = t)
	comment_edit.text_changed.connect(func(): comment.comment_text = comment_edit.text)
	
	tb.add_child(VSeparator.new())
	
	color_picker_button.custom_minimum_size=Vector2(48,28)
	color_picker_button.color = comment.background_color
	color_picker_button.flat=true
	color_picker_button.edit_intensity=false
	tb.add_child(color_picker_button)

	color_picker_button.get_picker().color_changed.connect(func(c: Color):
		_apply_color(c,c.lightened(0.35))
	)
	
	tb.move_child(free_from_frame_button, -1)
	tb.move_child(delete_button, -1)
	comment.changed.connect(_sync_from_node, CONNECT_DEFERRED)
	
	if comment.node_size:
		print(size)
		size=comment.node_size
		print(size)

## Realigns the controls if the resource is modified from the inspector (edit button).
func _sync_from_node() -> void:
	var comment: BehaviorComment = node
	
	if title_edit.text != comment.comment_title: 
		title_edit.text = comment.comment_title
	if comment_edit.text != comment.comment_text: 
		comment_edit.text = comment.comment_text
	if color_picker_button.color != comment.color:
		color_picker_button.color = comment.color
		_apply_color(comment.color,comment.color.lightened(0.35))

func _apply_color(bg: Color, bd:Color) -> void:
	set_indexed("theme_override_styles/panel:bg_color", bg)
	set_indexed("theme_override_styles/titlebar:bg_color", bg)
	set_indexed("theme_override_styles/panel_selected:bg_color", bg)
	set_indexed("theme_override_styles/panel_selected:border_color", bd)
	set_indexed("theme_override_styles/titlebar_selected:bg_color", bg)
	set_indexed("theme_override_styles/titlebar_selected:border_color", bd)
