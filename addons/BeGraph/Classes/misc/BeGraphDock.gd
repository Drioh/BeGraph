@tool
extends Control

@onready var graph_label: Label = %GraphLabel
@onready var info_button: Button = %InfoButton
@onready var save_button: Button = %SaveButton
@onready var edit_button: Button = %EditButton
@onready var close_button: Button = %CloseButton
@onready var graph_edit: BehaviorGraphEdit = %GraphEdit

var loaded_graph : BehaviorGraph = null

func _ready() -> void:
	info_button.pressed.connect(print_nodes_info)
	edit_button.pressed.connect(edit_graph)

## Debug utility that prints, for every [BehaviorGraphNode] child, its
## underlying [BehaviorNode]'s name, category, successors, instruction,
## variables (with their blackboard bindings) and conditions.
func print_nodes_info()->void:
	for node in loaded_graph.nodes:
		node.print_node_info()
		print("========================================================================")

func edit_graph()->void:
	EditorInterface.edit_resource(loaded_graph)

func load_graph(object: BehaviorGraph):
	loaded_graph= object
	
	var graph_info: String = object.resource_name if object.resource_name != "" else object.resource_path
	graph_label.text = "Loaded Behavior Graph: %s" % graph_info
	graph_edit.set_graph(object)
	
	
