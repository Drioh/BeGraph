@tool
## Read-only [GraphFrame] used by [BehaviorGraphDebugGraph] to render a [BehaviorFrame] during debugging.
## Displays the frame's title, tint color, and optional "Sequence" and "Memory" pill badges in the titlebar.
class_name BehaviorGraphDebugFrame
extends GraphFrame

var idle_tint : Color = Color(0.28, 0.4, 0.62, 0.7)
var is_sequence : bool = false
var memory : bool = false
var autoshrink : bool = true

var _sequence_pill : PanelContainer = null
var _memory_pill : PanelContainer = null

func setup(info: Dictionary) -> void:
	name = info["name"]
	var frame_title : String = info.get("title", "")
	title = frame_title
	
	idle_tint = info.get("tint_color", Color(0.28, 0.4, 0.62, 0.7))
	tint_color = idle_tint
	tint_color_enabled = true
	
	position_offset = info.get("position", Vector2.ZERO)
	size = info.get("size", Vector2(600, 400))
	autoshrink = info.get("autoshrink", true)
	is_sequence = info.get("is_sequence", false)
	memory = info.get("memory", false)

	_build_titlebar(frame_title)

func _build_titlebar(frame_title: String) -> void:
	var tb : HBoxContainer = get_titlebar_hbox()
	
	# Only display pills when is_sequence is true. Purely visual frames show no pills.
	if is_sequence:
		_sequence_pill = _create_pill("Sequence", Color(0.2, 0.48, 0.85, 0.9))
		tb.add_child(_sequence_pill)
		
		if memory:
			_memory_pill = _create_pill("Memory", Color(0.18, 0.65, 0.45, 0.9))
			tb.add_child(_memory_pill)

func _create_pill(text: String, bg_color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(4)
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", style)
	
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(label)
	return panel

## Makes the frame re-wrap its attached nodes when autoshrink is enabled.
func track(element: GraphElement) -> void:
	if not autoshrink:
		return
	if not element.resized.is_connected(_refresh_autoshrink):
		element.resized.connect(_refresh_autoshrink, CONNECT_DEFERRED)

func _refresh_autoshrink() -> void:
	if not autoshrink:
		return
	autoshrink_enabled = false
	autoshrink_enabled = true

## Updates the frame's tint color based on live execution status and fading freshness.
func update_status(status_color: Color, freshness: float) -> void:
	if freshness <= 0.0:
		tint_color = idle_tint
	else:
		tint_color = idle_tint.lerp(status_color, freshness * 0.75)
