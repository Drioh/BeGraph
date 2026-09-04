@tool
extends Control

@onready var graph_label: Label = %GraphLabel
@onready var info_button: Button = %InfoButton
@onready var edit_button: Button = %EditButton
@onready var close_button: Button = %CloseButton
@onready var graph_edit: BehaviorGraphEdit = %GraphEdit

var loaded_graph : BehaviorGraph

## Debug utility that prints, for every [BehaviorGraphNode] child, its
## underlying [BehaviorNode]'s name, category, successors, instruction,
## variables (with their blackboard bindings) and conditions.
func print_nodes_info()->void:
	for child in graph_edit.get_children():
		if child is BehaviorGraphNode:
			print("NODE: %s"%child.current_node)
			print("   Name: %s"%graph_edit._label_for_script(child.current_node.get_script().get_path()))
			print("   Category: %s"%child.current_node.node_category)
			print("   Successor(s): %s"%str(child.current_node.next))
			print("\nINSTRUCTION AND VARIABLES")
			print("   Node instruction: \"%s\""%child.current_node.instruction)
			for v in child.current_node.behavior_properties:
				print("   Variable %s"%v.name)
				print("      Value: %s"%v.value)
				print("      Blackboard connections: %s: %s"%[v.blackboard,v.blackboard_key])
			if child.current_node.conditions.size()>0:
				print("\nCONDITIONS")
				for condition in child.current_node.conditions:
					print("   Condition %s leads to %s"%[condition.text,condition.next])
			print("========================================================================")

func load_graph(object: BehaviorGraph):
	loaded_graph= object
	var graph_info: String = object.resource_name if object.resource_name != "" else object.resource_path
	graph_label.text = "Loaded Behavior Graph: %s" % graph_info
	graph_edit.set_graph(object)
	
	info_button.pressed.connect(print_nodes_info)
	edit_button.pressed.connect(EditorInterface.edit_resource.bind(loaded_graph))
