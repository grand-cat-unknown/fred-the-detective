class_name CaseLoader
extends RefCounted

const PLAYER_START_TILE := Vector2i(5, 13)
const FACT_DIR := "res://assets/facts"
const INTERACTABLE_DIR := "res://assets/interactables"
const INVENTORY_DIR := "res://assets/inventory"
const SUSPECT_DIR := "res://assets/suspects"
const FACT_IDS := [
	&"theo_granted_field_book_permission",
	&"has_field_book",
	&"has_evidence",
	&"lit_cigarette_found_1103",
	&"has_mags_cigarette_pouch",
	&"mags_confessed_bribe_master_key",
	&"julian_fake_idol_seen",
	&"has_julian_wax_idol",
	&"julian_confessed_fraud_not_murder",
	&"theo_cart_cell_missing_noticed",
	&"has_listening_device",
	&"iris_received_listening_device",
	&"iris_returned_transcribed_log",
	&"vivian_gave_chute_room_key",
	&"chute_room_door_open",
	&"mara_palms_shown",
	&"theo_palms_shown",
	&"iris_palms_shown",
	&"pemberton_palms_shown",
	&"has_stained_gloves",
]
const INTERACTABLE_IDS := [
	&"theo_field_book",
	&"room_1103_cigarette",
	&"mags_cigarette_pouch",
	&"julian_wax_idol",
	&"ghostbusters_gear_cart_inventory",
	&"iris_listening_device",
	&"chute_room_door",
	&"chute_output_cell",
	&"stained_gloves_bin",
]
const INVENTORY_IDS := [
	&"theo_field_book",
	&"evidence",
	&"mags_cigarette_pouch",
	&"julian_wax_idol",
	&"listening_device",
	&"transcribed_log",
	&"chute_room_key",
	&"stained_gloves",
]
const SUSPECT_IDS := [
	&"mara",
	&"theo",
	&"otis",
	&"iris",
	&"rival",
	&"bellhop",
	&"maid",
	&"manager",
]


static func load_default() -> CaseData:
	var case := CaseData.new()
	case.player_start_tile = PLAYER_START_TILE
	case.fact_definitions = _load_fact_definitions()
	case.interactables = _load_interactables()
	case.inventory_items = _load_inventory_items()
	var suspects: Array[SuspectData] = []
	for id in SUSPECT_IDS:
		var suspect := _load_suspect(id)
		if suspect != null:
			suspects.append(suspect)
	case.suspects = suspects
	return case


static func _load_suspect(id: StringName) -> SuspectData:
	var path := "%s/%s.tres" % [SUSPECT_DIR, id]
	if not ResourceLoader.exists(path):
		push_warning("Missing suspect resource: %s" % path)
		return null
	return load(path) as SuspectData


static func _load_fact_definitions() -> Array[FactDefinition]:
	var resources: Array[FactDefinition] = []
	for id in FACT_IDS:
		var resource := _load_fact_definition(id)
		if resource != null:
			resources.append(resource)
	for resource in _load_resources_from_dir(FACT_DIR):
		if resource is FactDefinition and not _has_fact_definition(resources, resource.id):
			resources.append(resource)
	return resources


static func _load_interactables() -> Array:
	var resources: Array = []
	for id in INTERACTABLE_IDS:
		var resource := _load_interactable(id)
		if resource != null:
			resources.append(resource)
	for resource in _load_resources_from_dir(INTERACTABLE_DIR):
		if (resource is InteractableDefinition or resource.has_method("resolve")) and not _has_interactable(resources, StringName(str(resource.get("object_id")))):
			resources.append(resource)
	return resources


static func _load_inventory_items() -> Array:
	var resources: Array = []
	for id in INVENTORY_IDS:
		var resource := _load_inventory_item(id)
		if resource != null:
			resources.append(resource)
	for resource in _load_resources_from_dir(INVENTORY_DIR):
		if resource is InventoryItemDefinition and not _has_inventory_item(resources, resource.item_id):
			resources.append(resource)
	return resources


static func _load_inventory_item(id: StringName) -> Resource:
	var path := "%s/%s.tres" % [INVENTORY_DIR, id]
	if not ResourceLoader.exists(path):
		push_warning("Missing inventory item resource: %s" % path)
		return null
	var resource := load(path) as Resource
	if resource == null or not resource.has_method("resolve"):
		push_warning("Inventory item resource cannot resolve: %s" % path)
		return null
	return resource


static func _has_inventory_item(resources: Array, id: StringName) -> bool:
	for resource in resources:
		if resource != null and StringName(str(resource.get("item_id"))) == id:
			return true
	return false


static func _load_fact_definition(id: StringName) -> FactDefinition:
	var path := "%s/%s.tres" % [FACT_DIR, id]
	if not ResourceLoader.exists(path):
		push_warning("Missing fact definition resource: %s" % path)
		return null
	return load(path) as FactDefinition


static func _load_interactable(id: StringName) -> Resource:
	var path := "%s/%s.tres" % [INTERACTABLE_DIR, id]
	if not ResourceLoader.exists(path):
		push_warning("Missing interactable resource: %s" % path)
		return null
	var resource := load(path) as Resource
	if resource == null or not resource.has_method("resolve"):
		push_warning("Interactable resource cannot resolve: %s" % path)
		return null
	return resource


static func _has_fact_definition(resources: Array[FactDefinition], id: StringName) -> bool:
	for resource in resources:
		if resource != null and resource.id == id:
			return true
	return false


static func _has_interactable(resources: Array, id: StringName) -> bool:
	for resource in resources:
		if resource != null and StringName(str(resource.get("object_id"))) == id:
			return true
	return false


static func _load_resources_from_dir(path: String) -> Array[Resource]:
	var resources: Array[Resource] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return resources

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var resource_path := "%s/%s" % [path, file_name]
			var resource := load(resource_path) as Resource
			if resource != null:
				resources.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()
	return resources
