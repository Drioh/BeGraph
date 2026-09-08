@tool
extends Control

@onready var graph_label: Label = %GraphLabel
@onready var save_button: Button = %SaveButton
@onready var save_as_button: Button = %SaveAsButton
@onready var edit_button: Button = %EditButton
@onready var close_button: Button = %CloseButton
@onready var graph_edit: BehaviorGraphEdit = %GraphEdit

var loaded_graph : BehaviorGraph = null

func _ready() -> void:
	edit_button.pressed.connect(edit_graph)

func edit_graph()->void:
	EditorInterface.edit_resource(loaded_graph)

func load_graph(object: BehaviorGraph):
	loaded_graph= object
	if loaded_graph == null:
		graph_label.text = "Loaded Behavior Graph:"
		graph_edit.set_graph(object)
		EditorInterface.edit_resource(null)
		return
	var graph_info: String = object.resource_name if object.resource_name != "" else object.resource_path
	graph_label.text = "Loaded Behavior Graph: %s" % graph_info
	graph_edit.set_graph(object)
	
	
