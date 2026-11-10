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

const OBP : String = "overridable_blackboard_properties"

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

static func clean_key(key:String)->StringName:
	return key.get_slice("/", 1) if key.begins_with(BG.OBP) else key

static func dirty_key(key:String)->StringName:
	return key if key.begins_with(BG.OBP) else BG.OBP+"/"+key

static func is_type_compatible(source_type: int, target_type: int) -> bool:
	return source_type == TYPE_NIL or target_type == TYPE_NIL or source_type in CONVERSION_DICT.get(target_type, [])

static func format_decorator_summary(decorator: Dictionary, prefix: String = "Decorator: ") -> String:
	match String(decorator.get("type", "none")):
		"none", "":
			return ""
		"inverter":
			return "%sInverter" % prefix
		"force":
			var variant : int = int(decorator.get("variant", 0))
			return "%sForce %s" % [prefix, "Success" if variant == 0 else "Failure"]
		"repeater":
			var variant : int = int(decorator.get("variant", 0))
			var between : float = decorator.get("between_delay", 0.0)
			var detail : String
			match variant:
				0:
					var count : int = int(decorator.get("count", 3))
					detail = "Times (%s)" % (str(count) if count > 0 else "infinite")
				1:
					var timeout : float = decorator.get("timeout", 0.0)
					detail = "Until Success (timeout %ss)" % (str(timeout) if timeout > 0.0 else "none")
				_:
					var timeout2 : float = decorator.get("timeout", 0.0)
					detail = "Until Failure (timeout %ss)" % (str(timeout2) if timeout2 > 0.0 else "none")
			return "%sRepeater - %s, delay %ss" % [prefix, detail, str(between)]
		"time_limit":
			var on_timeout : int = int(decorator.get("on_timeout", 0))
			return "%sTime Limit %ss (on timeout: %s)" % [prefix, str(decorator.get("seconds", 5.0)), "Abort" if on_timeout == 0 else "Let Run"]
		"cooldown":
			var mode : int = int(decorator.get("cooldown_mode", 0))
			return "%sCooldown %ss (%s)" % [prefix, str(decorator.get("seconds", 2.0)), "Always" if mode == 0 else "On Success"]
		"delay":
			var delay_mode : int = int(decorator.get("delay_mode", 0))
			return "%sDelay %ss (%s)" % [prefix, str(decorator.get("seconds", 1.0)), "Before" if delay_mode == 0 else "After"]
		"condition":
			var key : String = String(decorator.get("blackboard_key", &""))
			var exp_str : String = "True" if int(decorator.get("condition_expected", 0)) == 0 else "False"
			return "%sCondition (%s == %s)" % [prefix, key if key != "" else "(unbound)", exp_str]
		var other:
			return "%s%s" % [prefix, other]

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
