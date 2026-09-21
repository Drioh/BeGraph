@tool
## Visual [GraphNode] per un [AccessPointNode]: angoli sinistri arrotondati, destri dritti, un solo slot d'uscita a destra, e un campo "label:" ([LineEdit]) legato a [member AccessPointNode.label].
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
