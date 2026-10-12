class_name BG extends Node

#@export_custom(BG.HINT_ENUM,BG.ENUMERATOR + "enumerator_name") var var_name : enumerator_name = 0
#@export_custom(BG.HINT_ENUM,BG.PROPERTY + "val_1,val_2,...,val_n") var var_name : enumerator_name = 0
#@export_custom(BG.HINT_ENUM,BG.PROPERTY + "val_1,val_2,...,val_n") var var_name : int = 0
const HINT_NONE : PropertyHint = PROPERTY_HINT_NONE
const HINT_ENUM : PropertyHint = PROPERTY_HINT_ENUM
const HINT_MULTILINE_TEXT : PropertyHint = PROPERTY_HINT_MULTILINE_TEXT

const PROPERTY : String = "BeGraph:property:"
const ENUMERATOR : String = "BeGraph:enumerator:"
const CONDITION : String = "BeGraph:condition:"

## Messages exchanged via EngineDebugger between game (Bridge) and editor (Plugin).
## Formerly its own class (BeGraphProtocol, Debug/BehaviorGraphProtocol.gd), folded in here
## so every addon-wide constant lives in a single place.
class Protocol:
	const PREFIX : String = "begraph"
	const GRAPH : String = "begraph:graph"
	const STATUS : String = "begraph:status"
	const PROPERTIES : String = "begraph:properties"
	const BLACKBOARD : String = "begraph:blackboard"
	const REMOVED : String = "begraph:removed"

	static func safe_value(value: Variant) -> Variant:
		return str(value) if value is Object else value

## Maps each [enum Variant.Type] to the list of [enum Variant.Type] values that are considered compatible with it.
const CONVERSION_DICT: Dictionary = {
	TYPE_NIL: [
		TYPE_NIL,
	],

	TYPE_BOOL: [
		TYPE_BOOL,
		TYPE_INT,
		TYPE_FLOAT,
	],

	TYPE_INT: [
		TYPE_INT,
		TYPE_FLOAT,
		TYPE_BOOL,
		TYPE_STRING,
	],

	TYPE_FLOAT: [
		TYPE_FLOAT,
		TYPE_INT,
		TYPE_BOOL,
		TYPE_STRING,
	],

	TYPE_STRING: [
		TYPE_STRING,
		TYPE_STRING_NAME,
		TYPE_NODE_PATH,
	],

	TYPE_VECTOR2: [
		TYPE_VECTOR2,
		TYPE_VECTOR2I,
	],

	TYPE_VECTOR2I: [
		TYPE_VECTOR2I,
		TYPE_VECTOR2,
	],

	TYPE_RECT2: [
		TYPE_RECT2,
		TYPE_RECT2I,
	],

	TYPE_RECT2I: [
		TYPE_RECT2I,
		TYPE_RECT2,
	],

	TYPE_VECTOR3: [
		TYPE_VECTOR3,
		TYPE_VECTOR3I,
	],

	TYPE_VECTOR3I: [
		TYPE_VECTOR3I,
		TYPE_VECTOR3,
	],

	TYPE_TRANSFORM2D: [
		TYPE_TRANSFORM2D,
	],

	TYPE_VECTOR4: [
		TYPE_VECTOR4,
		TYPE_VECTOR4I,
	],

	TYPE_VECTOR4I: [
		TYPE_VECTOR4I,
		TYPE_VECTOR4,
	],

	TYPE_PLANE: [
		TYPE_PLANE,
		TYPE_VECTOR3,
	],

	TYPE_QUATERNION: [
		TYPE_QUATERNION,
		TYPE_BASIS,
	],

	TYPE_AABB: [
		TYPE_AABB,
	],

	TYPE_BASIS: [
		TYPE_BASIS,
		TYPE_QUATERNION,
	],

	TYPE_TRANSFORM3D: [
		TYPE_TRANSFORM3D,
		TYPE_PROJECTION,
	],

	TYPE_PROJECTION: [
		TYPE_PROJECTION,
		TYPE_TRANSFORM3D,
	],

	TYPE_COLOR: [
		TYPE_COLOR,
		TYPE_STRING,
	],

	TYPE_STRING_NAME: [
		TYPE_STRING_NAME,
		TYPE_STRING,
	],

	TYPE_NODE_PATH: [
		TYPE_NODE_PATH,
		TYPE_STRING,
	],

	TYPE_RID: [
		TYPE_RID,
	],

	TYPE_OBJECT: [
		TYPE_OBJECT,
		TYPE_NIL,
	],

	TYPE_CALLABLE: [
		TYPE_CALLABLE,
	],

	TYPE_SIGNAL: [
		TYPE_SIGNAL,
	],

	TYPE_DICTIONARY: [
		TYPE_DICTIONARY,
	],

	TYPE_ARRAY: [
		TYPE_ARRAY,
	],

	TYPE_PACKED_BYTE_ARRAY: [
		TYPE_PACKED_BYTE_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_INT32_ARRAY: [
		TYPE_PACKED_INT32_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_INT64_ARRAY: [
		TYPE_PACKED_INT64_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_FLOAT32_ARRAY: [
		TYPE_PACKED_FLOAT32_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_FLOAT64_ARRAY: [
		TYPE_PACKED_FLOAT64_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_STRING_ARRAY: [
		TYPE_PACKED_STRING_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_VECTOR2_ARRAY: [
		TYPE_PACKED_VECTOR2_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_VECTOR3_ARRAY: [
		TYPE_PACKED_VECTOR3_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_COLOR_ARRAY: [
		TYPE_PACKED_COLOR_ARRAY,
		TYPE_ARRAY,
	],

	TYPE_PACKED_VECTOR4_ARRAY: [
		TYPE_PACKED_VECTOR4_ARRAY,
		TYPE_ARRAY,
	],
}
