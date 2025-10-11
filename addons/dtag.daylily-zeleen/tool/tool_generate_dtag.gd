@tool
extends EditorScript

var gen_target_file := "res://dtag.gen.gd"


func _run() -> void:
	var gd_script_files := _get_gd_scripts_recursively()
	var tag_definitions: Dictionary[String, Dictionary] = {}
	for f in gd_script_files:
		var script := ResourceLoader.load(f, "GDScript", ResourceLoader.CACHE_MODE_IGNORE) as Script
		_extract_tag_definitions(script, tag_definitions)

	var text := """# This file is generated, any modify maybe discard.
class_name DTag

"""
	


func _get_gd_scripts_recursively(base_dir := "res://", r_files:PackedStringArray=[]) -> PackedStringArray:
	if base_dir == "res://addons/":
		return r_files

	for f in DirAccess.get_files_at(base_dir):
		if f.begins_with("."):
			continue

		if f.get_extension().to_lower() == "gd":
			r_files.push_back(base_dir.path_join(f))

	for d in DirAccess.get_directories_at(base_dir):
		if d.begins_with("."):
			continue

		var next_dir := base_dir.path_join(d)
		if next_dir.begins_with("res://addons"):
			continue

		_get_gd_scripts_recursively(next_dir, r_files)

	return r_files


func _extract_tag_definitions(script: GDScript, r_tag_definitions: Dictionary[String, Dictionary]) -> Dictionary[String, Dictionary]:
	var cosntant_map := script.get_script_constant_map()

	for k in cosntant_map:
		if not typeof(k) in [TYPE_STRING, TYPE_STRING_NAME]:
			continue
		var v: Variant = cosntant_map.get(k, null)
		if typeof(v) != TYPE_DICTIONARY:
			continue
		if not _is_valid_definistion_dictionary_recursively(v):
			continue

		if not r_tag_definitions.has(k):
			r_tag_definitions[k] = {}

		_merge_tag_definition_recursively(r_tag_definitions[k], v)

	return r_tag_definitions


func _merge_tag_definition_recursively(ori: Dictionary, dest: Dictionary) -> void:
	for k in dest:
		if not ori.has(k) or typeof(ori[k]) != TYPE_DICTIONARY:
			ori[k] = {}

		var v = dest[k]
		match typeof(v):
			TYPE_STRING, TYPE_STRING_NAME, TYPE_NIL:
				if ori[k].is_empty():
					ori[k] = v if typeof(v) != TYPE_NIL else ""
			TYPE_DICTIONARY:
				_merge_tag_definition_recursively(ori[k], v)


func _is_valid_definistion_dictionary_recursively(dict: Dictionary) -> bool:
	for k in dict:
		if not typeof(k) in [TYPE_STRING, TYPE_STRING_NAME]:
			return false
		var v : Variant = dict[dict]
		match typeof(v):
			TYPE_STRING, TYPE_STRING_NAME, TYPE_NIL:
				pass
			TYPE_DICTIONARY:
				if not _is_valid_definistion_dictionary_recursively(v):
					return false
			_:
				return false
	return true
