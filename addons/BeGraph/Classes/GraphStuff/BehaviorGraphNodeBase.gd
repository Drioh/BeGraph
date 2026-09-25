@tool
## Base class per ogni [GraphNode] visuale usato da [BehaviorGraphEdit]: [BehaviorGraphNode] (rendering generico), [CommentGraphNode] e [AccessPointGraphNode] (scene dedicate) estendono tutti questa classe.[br]
## Contiene le parti comuni a ogni tipo di nodo: riferimento al [BehaviorNode], sync titolo/posizione, bottoni edit/delete in titlebar, applicazione colori di categoria.
class_name BehaviorGraphNodeBase
extends GraphNode

## Il [BehaviorGraphEdit] proprietario.
@export var graph_edit: BehaviorGraphEdit

## Il [BehaviorNode] rappresentato da questo nodo visuale.
var node: BehaviorNode

## Assegna [param n], configura slot/titolo/posizione e i bottoni edit/delete in titlebar, poi chiama [method _on_node_set] affinché le sottoclassi costruiscano il proprio corpo/comportamento specifico.
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

## Override per costruire il corpo di questo nodo / collegare i suoi controlli specifici, una volta che [member node] è disponibile.
func _on_node_set() -> void:
	pass

## Applica i colori sfondo/bordo/titlebar salvati in [ProjectSettings] sotto [param category] (es. [code]"BeGraph/colors/node_colors/action_node"[/code]) a pannello, titlebar e ogni slot.
func set_node_color(category: String) -> void:
	var background_color: Color = ProjectSettings.get_setting("%s/background_color" % category)
	var selection_color: Color = ProjectSettings.get_setting("%s/border_color" % category)
	set_indexed("theme_override_styles/panel:bg_color", background_color)
	set_indexed("theme_override_styles/panel_selected:bg_color", background_color)
	set_indexed("theme_override_styles/titlebar:bg_color", background_color)
	set_indexed("theme_override_styles/titlebar_selected:bg_color", background_color)

	set_indexed("theme_override_styles/panel_selected:border_color", selection_color)
	set_indexed("theme_override_styles/titlebar_selected:border_color", selection_color)
	for slot in get_child_count():
		set("slot/%s/left_color" % slot, selection_color)
		set("slot/%s/right_color" % slot, selection_color)
