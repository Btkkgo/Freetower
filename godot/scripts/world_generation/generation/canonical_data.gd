class_name CanonicalData
extends RefCounted

const EXCLUDED_RUNTIME_KEYS := {
	"duration_ms": true,
	"renderer": true,
	"adapter": true,
	"display_server": true,
	"process_id": true,
	"node_instance_id": true,
	"capture_path": true,
	"timestamp": true,
	"generated_node_count": true,
	"multimesh_count": true,
}
const FLOAT_QUANTUM := 0.000001


static func canonicalize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			var source: Dictionary = value
			var keys := source.keys()
			keys.sort_custom(func(left: Variant, right: Variant) -> bool: return str(left) < str(right))
			var result := {}
			for key in keys:
				var key_string := str(key)
				if EXCLUDED_RUNTIME_KEYS.has(key_string):
					continue
				result[key_string] = canonicalize(source[key])
			return result
		TYPE_ARRAY:
			var result: Array = []
			for item in value:
				result.append(canonicalize(item))
			return result
		TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, \
			TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY, TYPE_PACKED_VECTOR2_ARRAY, \
			TYPE_PACKED_VECTOR3_ARRAY, TYPE_PACKED_COLOR_ARRAY:
			var result: Array = []
			for item in value:
				result.append(canonicalize(item))
			return result
		TYPE_FLOAT:
			var quantized := snappedf(float(value), FLOAT_QUANTUM)
			return 0.0 if is_zero_approx(quantized) else quantized
		TYPE_VECTOR2:
			var vector: Vector2 = value
			return [canonicalize(vector.x), canonicalize(vector.y)]
		TYPE_VECTOR3:
			var vector: Vector3 = value
			return [canonicalize(vector.x), canonicalize(vector.y), canonicalize(vector.z)]
		TYPE_TRANSFORM3D:
			var transform: Transform3D = value
			return [
				canonicalize(transform.basis.x),
				canonicalize(transform.basis.y),
				canonicalize(transform.basis.z),
				canonicalize(transform.origin),
			]
		TYPE_COLOR:
			var color: Color = value
			return [
				canonicalize(color.r), canonicalize(color.g),
				canonicalize(color.b), canonicalize(color.a),
			]
		TYPE_OBJECT:
			if value != null and value.has_method("to_canonical_data"):
				return canonicalize(value.to_canonical_data())
			return null
		_:
			return value


static func to_json(value: Variant) -> String:
	return JSON.stringify(canonicalize(value), "", false)


static func sha256(value: Variant) -> String:
	var hashing := HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(to_json(value).to_utf8_buffer())
	return hashing.finish().hex_encode()
