@tool
extends Node2D

@export var title: String = "Station Title":
	set(v):
		title = v
		_update_ui()

@export_multiline var summary: String = "Summary of what this BehaviorGraph demonstrates.":
	set(v):
		summary = v
		_update_ui()

@export var nodes_used: PackedStringArray = ["Access Point", "Action Node"]:
	set(v):
		nodes_used = v
		_update_ui()

@export var station_color: Color = Color(0.18, 0.55, 0.95, 1.0):
	set(v):
		station_color = v
		_update_ui()

@onready var title_label: Label = get_node_or_null("%TitleLabel")
@onready var summary_label: Label = get_node_or_null("%SummaryLabel")
@onready var nodes_container: HFlowContainer = get_node_or_null("%NodesContainer")
@onready var header_bar: ColorRect = get_node_or_null("%HeaderBar")

func _ready() -> void:
	_update_ui()

func _update_ui() -> void:
	if title_label:
		title_label.text = title
	if summary_label:
		summary_label.text = summary
	if header_bar:
		header_bar.color = station_color

	if nodes_container:
		for child in nodes_container.get_children():
			child.queue_free()

		for node_name in nodes_used:
			var badge := PanelContainer.new()
			var style := StyleBoxFlat.new()
			style.bg_color = Color(0.0, 0.0, 0.0, 0.902)
			style.border_color = station_color.lerp(Color.WHITE, 0.25)
			style.set_border_width_all(1)
			style.set_corner_radius_all(4)
			style.content_margin_left = 6
			style.content_margin_right = 6
			style.content_margin_top = 2
			style.content_margin_bottom = 2
			badge.add_theme_stylebox_override("panel", style)

			var lbl := Label.new()
			lbl.text = node_name
			lbl.add_theme_font_size_override("font_size", 11)
			lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
			badge.add_child(lbl)
			nodes_container.add_child(badge)
