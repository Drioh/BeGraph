@tool
## Visual [GraphNode] for an [AccessPointNode]: rounded left corners, square right corners, a single output slot on the right, and a "label:" field ([LineEdit]) bound to [member AccessPointNode.label].
class_name BehaviorGraphAccessPoint
extends BehaviorGraphNodeBase

@onready var label_edit: LineEdit = %LabelEdit

func _on_node_set() -> void:
	var ap: AccessPointNode = node
	label_edit.text = ap.label
	label_edit.text_changed.connect(func(t: String): ap.label = t)
	ap.changed.connect(func():
		if label_edit.text != ap.label: 
			label_edit.text = ap.label
	, CONNECT_DEFERRED)
	set_node_color("BeGraph/colors/node_colors/%s" % node.node_category)
