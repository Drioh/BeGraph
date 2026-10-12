@tool
## Base class for every visual [GraphNode] used by [BehaviorGraphEdit]: [BehaviorGraphNode] (generic rendering), [BehaviorGraphComment] and [BehaviorGraphAccessPoint] (dedicated scenes) all extend this class.[br]
## Contains the parts common to every node type: reference to the [BehaviorNode], title/position sync, edit/delete buttons in the titlebar, category color application.
class_name BehaviorGraphNodeBase
extends GraphNode

## The owning [BehaviorGraphEdit].o.
@export var graph_edit: BehaviorGraphEdit
## Titlebar button that removes this node from its frame. Visible only while the node is inside one (see [method set_framed]).
var free_from_frame_button: Button
## Titlebar button that deletes this node.
var delete_button: Button
var breakpoint_button: Button
var mute_button: Button

## The [BehaviorNode] represented by this visual node.
var node: BehaviorNode
## Assigns [param n], configures slot/title/position and the edit/delete buttons in the titlebar, then calls [method _on_node_set] so subclasses can build their own specific body/behavior.
func set_node(n: BehaviorNode) -> void:
	node = n
	set_slot_enabled_right(0, node.output)
	set_slot_enabled_left(0, node.input)

	title = self.name.validate_node_name()
	node.resource_name = title
	position_offset_changed.connect(func(): node.position_in_graph = position_offset)

	var tb: HBoxContainer = get_titlebar_hbox()
	tb.add_theme_constant_override("separation", 0)
	tb.get_child(0).add_theme_font_size_override("font_size", 12)
	tb.get_child(0).self_modulate.a = 0.5
	
	free_from_frame_button = Button.new()
	free_from_frame_button.flat = true
	free_from_frame_button.icon = load("res://addons/BeGraph/Icons/free_frame.svg")
	free_from_frame_button.tooltip_text = "Free from frame"
	free_from_frame_button.visible = false
	# The name is read at press time, not captured now, so it's always the current one.
	free_from_frame_button.pressed.connect(func(): graph_edit.detach_node_from_frame(name))
	tb.add_child(free_from_frame_button)
	
	if node.breakpoint_enabled:
		breakpoint_button = Button.new()
		breakpoint_button.flat = true
		breakpoint_button.text = "B"
		breakpoint_button.tooltip_text="If enabled, when this graph's flow reaches this note, a breakpoint is triggered.\nMutually exlusive with the \"mute\" feature"
		breakpoint_button.toggle_mode=true
		breakpoint_button.toggled.connect(func(p):
			node.breakpoint_enabled=p
			if p and node.mute_enabled:
				mute_button.button_pressed=false
			breakpoint_button.modulate=EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color") if p else Color.WHITE
			)
		tb.add_child(breakpoint_button)
		breakpoint_button.button_pressed=node.breakpoint_enabled
	
	if node.mute_enabled:
		mute_button = Button.new()
		mute_button.flat = true
		mute_button.text = "M"
		mute_button.tooltip_text="If enabled, this node gets skipped and its first child (or condition) gets triggered.\nMutually exlusive with the \"breakpoint\" feature"
		mute_button.toggle_mode=true
		mute_button.toggled.connect(func(p):
			node.mute_enabled=p
			mute_button.modulate = EditorInterface.get_editor_settings().get_setting("interface/theme/accent_color") if p else Color.WHITE
			if p and node.breakpoint_enabled:
				breakpoint_button.button_pressed=false
			modulate.a=0.5 if p else 1.0
			)
		tb.add_child(mute_button)
		mute_button.button_pressed=node.mute_enabled
	
	delete_button = Button.new()
	var del_array : Array[StringName] = [StringName(self.name)]
	delete_button.flat = true
	delete_button.icon = load("res://addons/BeGraph/Icons/close_icon.svg")
	delete_button.pressed.connect(graph_edit._on_delete_nodes_request.bind(del_array))
	tb.add_child(delete_button)
	
	_on_node_set()

## Override to build this node's body / wire up its specific controls, once [member node] is available.
func _on_node_set() -> void:
	pass

## Applies the background/border/titlebar colors saved in [ProjectSettings] under [param category] ... to the panel, titlebar and every slot.
func set_node_color(category: String) -> void:
	var background_color: Color = ProjectSettings.get_setting("%s/background" % category)
	var selection_color: Color = ProjectSettings.get_setting("%s/border" % category)
	set_indexed("theme_override_styles/panel:bg_color", background_color)
	set_indexed("theme_override_styles/panel_selected:bg_color", background_color)
	set_indexed("theme_override_styles/titlebar:bg_color", background_color)
	set_indexed("theme_override_styles/titlebar_selected:bg_color", background_color)

	set_indexed("theme_override_styles/panel_selected:border_color", selection_color)
	set_indexed("theme_override_styles/titlebar_selected:border_color", selection_color)
	for slot in get_child_count():
		set("slot/%s/left_color" % slot, selection_color)
		set("slot/%s/right_color" % slot, selection_color)

## Shows or hides the "free from frame" button. Called by [BehaviorGraphEdit] whenever frame attachments change.
func set_framed(framed: bool) -> void:
	if free_from_frame_button:
		free_from_frame_button.visible = framed
