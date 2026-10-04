@tool
## Base class for every visual [GraphNode] used by [BehaviorGraphEdit]: [BehaviorGraphNode] (generic rendering), [BehaviorGraphComment] and [BehaviorGraphAccessPoint] (dedicated scenes) all extend this class.[br]
## Contains the parts common to every node type: reference to the [BehaviorNode], title/position sync, edit/delete buttons in the titlebar, category color application.
class_name BehaviorGraphNodeBase
extends GraphNode

## The owning [BehaviorGraphEdit].o.
@export var graph_edit: BehaviorGraphEdit

## ## The [BehaviorNode] represented by this visual node.
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

	var delete_button := Button.new()
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
	print("%s/background_color"%category)
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
