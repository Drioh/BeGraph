@tool
extends Control
## Root control of the BeGraph bottom dock: hosts the toolbar (edit/save/save-as/close buttons) and the [BehaviorGraphEdit] used to visually edit the currently loaded [BehaviorGraph].

## Label showing the name/path of the currently loaded [member loaded_graph].
@onready var graph_label: Label = %GraphLabel
## Button that opens [member loaded_graph] in the main editor inspector.
@onready var edit_button: Button = %EditButton

## Button that creates a new Behavior Graph
@onready var new_button: Button = %NewButton
## Button that loads a Behavior Graph
@onready var load_button: Button = %LoadButton

## Button that saves [member loaded_graph] to its existing resource path.
@onready var save_button: Button = %SaveButton
## Button that opens a file dialog to save [member loaded_graph] to a new path.
@onready var save_as_button: Button = %SaveAsButton
## Button that hides this dock.
@onready var close_button: Button = %CloseButton
@onready var info_button: Button = %InfoButton
## The [BehaviorGraphEdit] instance used to visually edit [member loaded_graph].
@onready var graph_edit: BehaviorGraphEdit = %GraphEdit

@onready var info_panel: PanelContainer = %InfoPanel
## The [BehaviorGraph] resource currently loaded in this dock, or [code]null[/code] if none is loaded.
var loaded_graph : BehaviorGraph = null

## Connects [member edit_button] to [method edit_graph].
func _ready() -> void:
	edit_button.pressed.connect(edit_graph)
	info_button.pressed.connect(func():
		if info_button.button_pressed: info_panel.show()
		else: info_panel.hide())
## Opens [member loaded_graph] in the main editor's inspector/resource editor.
func edit_graph()->void:
	EditorInterface.edit_resource(loaded_graph)

## Loads [param object] as the graph being edited: updates [member loaded_graph], refreshes [member graph_label] with its name (or resource path, as a fallback), and forwards it to [member graph_edit]. Passing [code]null[/code] unloads the current graph and clears the editor's inspected resource.
func load_graph(object: BehaviorGraph):
	loaded_graph = object
	graph_edit.set_graph(object)
	if loaded_graph == null:
		graph_label.text = "Loaded Behavior Graph:"
		EditorInterface.edit_resource(null)
		return
	refresh_label()

func refresh_label() -> void:
	if loaded_graph == null:
		return
	var graph_info: String = loaded_graph.resource_name if loaded_graph.resource_name != "" else loaded_graph.resource_path
	graph_label.text = "Loaded Behavior Graph: %s" % graph_info
