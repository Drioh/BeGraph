@tool
class_name MoveCharacter
extends BehaviorNode

const DISPLAY_NAME : String = "Move"

func tick()->Status:
	return Status.SUCCESS

func set_instruction() -> String:
	return "MAMMA, stampo lo {str}, come faccio?{sandro}, {variabile_nulla}, senza contare che {sandro}"

func set_node_category()->String: return "action_node"

func set_input()->bool: return true

func set_output()->bool : return false

func set_conditions() -> PackedStringArray:
	return PackedStringArray([
		"Prima Condizione",
		"Questa è la seconda condizione",
		"Questa è la terza condizione con la variabile {sandro}"
	])

func set_allows_multiple_outputs() -> bool: return false

func set_properties()-> void:
	_add_behavior_property("str",Vector2(1,1))
	_add_behavior_property("sandro","")
	_add_behavior_property("variabile_nulla",0,PROPERTY_HINT_ENUM,"primo_valore,secondo_valore,terzo_valore")
	
