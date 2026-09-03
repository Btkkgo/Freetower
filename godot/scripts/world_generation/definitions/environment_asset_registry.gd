class_name EnvironmentAssetRegistry
extends Resource

@export var registry_id := "foundation_registry"
@export var assets: Array = []

var _index := {}
var _duplicate_ids := PackedStringArray()


func build_index() -> Array[Dictionary]:
	_index.clear()
	_duplicate_ids.clear()
	var ordered := assets.duplicate()
	ordered.sort_custom(func(left: Resource, right: Resource) -> bool: return left.asset_id < right.asset_id)
	for asset in ordered:
		if _index.has(asset.asset_id):
			_duplicate_ids.append(asset.asset_id)
		else:
			_index[asset.asset_id] = asset
	var errors: Array[Dictionary] = []
	for asset_id in _duplicate_ids:
		errors.append({"code": "DUPLICATE_ASSET_ID", "resource_id": asset_id, "field": "asset_id", "message": "Asset ID must be unique"})
	return errors


func duplicate_ids() -> PackedStringArray:
	build_index()
	return _duplicate_ids.duplicate()


func resolve(asset_id: String, production_mode: bool = false) -> Dictionary:
	build_index()
	if _duplicate_ids.has(asset_id) or not _index.has(asset_id):
		return {"ok": false, "error": "MISSING APPROVED ASSET", "asset_id": asset_id}
	var asset: Resource = _index[asset_id]
	if production_mode and (asset.is_debug_proxy or not asset.production_approved):
		return {"ok": false, "error": "MISSING APPROVED ASSET", "asset_id": asset_id}
	return {"ok": true, "asset": asset, "asset_id": asset_id}


func find_by_tags(tags: PackedStringArray, biome_id: String, production_mode: bool = false) -> Array:
	var matches: Array = []
	var ordered := assets.duplicate()
	ordered.sort_custom(func(left: Resource, right: Resource) -> bool: return left.asset_id < right.asset_id)
	for asset in ordered:
		if production_mode and (asset.is_debug_proxy or not asset.production_approved):
			continue
		if not asset.allowed_biomes.is_empty() and not asset.allowed_biomes.has(biome_id):
			continue
		for tag in tags:
			if asset.asset_tags.has(tag):
				matches.append(asset)
				break
	return matches


func to_canonical_data() -> Dictionary:
	var records: Array = []
	for asset in assets:
		records.append(asset.to_canonical_data())
	records.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return left.asset_id < right.asset_id)
	return {"assets": records, "registry_id": registry_id}
