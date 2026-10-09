class_name BG extends Node

const HINT_NONE : PropertyHint = PROPERTY_HINT_NONE

#@export_custom(BG.HINT_ENUM,BG.ENUMERATOR + "enumerator_name") var var_name : enumerator_name = 0
#@export_custom(BG.HINT_ENUM,BG.PROPERTY + "val_1,val_2,...,val_n") var var_name : enumerator_name = 0
#@export_custom(BG.HINT_ENUM,BG.PROPERTY + "val_1,val_2,...,val_n") var var_name : int = 0
const HINT_ENUM : PropertyHint = PROPERTY_HINT_ENUM

const HINT_MULTILINE_TEXT : PropertyHint = PROPERTY_HINT_MULTILINE_TEXT

const PROPERTY : String = "BeGraph:property:"

const ENUMERATOR : String = "BeGraph:enumerator:"

const CONDITION : String = "BeGraph:condition:"
