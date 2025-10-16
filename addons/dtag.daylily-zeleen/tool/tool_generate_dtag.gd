@tool
extends EditorScript

var gen_target_file := "res://dtag_def.gen.gd"


func _run() -> void:
	var processed_scripts: Array[Script]

	var gd_script_files := _get_gd_scripts_recursively()
	var tag_definitions: Dictionary[String, Dictionary] = {}
	for f in gd_script_files:
		var script := ResourceLoader.load(f, "GDScript", ResourceLoader.CACHE_MODE_IGNORE_DEEP) as Script
		_extract_tag_definitions(script, processed_scripts, tag_definitions)

	# Generate
	var identifiers: PackedStringArray
	var text := "# NOTE: This file is generated, any modify maybe discard.\n"
	text += "class_name DTagDef\n\n"
	for tag_namespace in tag_definitions:
		text += "\n"
		text += "const %s = {\n" % tag_namespace
		text += _generate_tag_text_recursively(tag_definitions[tag_namespace], tag_namespace, identifiers)
		text += "}\n"

	var class_list := ClassDB.get_class_list()
	var global_class_list := ProjectSettings.get_global_class_list().map(func(c: Dictionary) -> String: return c.class)
	for identifier in identifiers:
		if class_list.has(identifier) or global_class_list.has(identifier):
			print_rich("[color=yellow][WARN] DTag: tag \"%s\" is a class name.[/color]" % identifier)

	var fa := FileAccess.open(gen_target_file, FileAccess.WRITE)
	if not is_instance_valid(fa):
		printerr("[ERROR] DTag: open \"%s\" failed, %s." % [gen_target_file, error_string(FileAccess.get_open_error())])
		return

	fa.store_string(text)
	fa.close()

	var opened_scripts := EditorInterface.get_script_editor().get_open_scripts()
	for i in range(opened_scripts.size()):
		var script := opened_scripts[i] as Script
		if script.resource_path == gen_target_file:
			var se := EditorInterface.get_script_editor().get_open_script_editors().get(i) as ScriptEditorBase
			if is_instance_valid(se):
				var te := se.get_base_editor() as CodeEdit
				if is_instance_valid(te):
					te.text = text
					te.tag_saved_version()
			break

	print("DTag: \"%s\" is generated." % [gen_target_file])


#region Extract Definitions
func _get_gd_scripts_recursively(base_dir := "res://", r_files: PackedStringArray = []) -> PackedStringArray:
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


# Return value format example: {
# 	Namespace1 = {
# 		Namespace2 = {
# 			A = "xxx",
# 		}
# 		B = "xxx",
# 		C = "",
# 	},
# 	Namespace3 = {
# 		A = "",
# 	},
# }
func _extract_tag_definitions(script: GDScript, processed_scripts: Array[Script], r_tag_definitions: Dictionary[String, Dictionary]) -> Dictionary[String, Dictionary]:
	if processed_scripts.has(script):
		return r_tag_definitions

	if script.get_base_script() != (DTagDefinition as Script):
		return r_tag_definitions

	processed_scripts.push_back(script)
	
	var constant_map := script.get_script_constant_map()

	for k in constant_map:
		if not typeof(k) in [TYPE_STRING, TYPE_STRING_NAME]:
			continue
		var v: Variant = constant_map.get(k, null)
		if v is Script:
			_extract_tag_definitions(v, processed_scripts, r_tag_definitions)
			continue

		if typeof(v) != TYPE_DICTIONARY:
			continue
		if not _is_valid_definition_dictionary_recursively(v):
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


func _is_valid_definition_dictionary_recursively(dict: Dictionary) -> bool:
	for k in dict:
		if not typeof(k) in [TYPE_STRING, TYPE_STRING_NAME]:
			return false
		var v: Variant = dict[k]
		match typeof(v):
			TYPE_STRING, TYPE_STRING_NAME, TYPE_NIL:
				pass
			TYPE_DICTIONARY:
				if not _is_valid_definition_dictionary_recursively(v):
					return false
			_:
				return false
	return true
#endregion Extract Definitions


#region Generate
func _generate_tag_text_recursively(definition: Dictionary, prev_tag: String, r_identifiers: PackedStringArray, depth := 0) -> String:
	var ret := ""
	for key: String in definition:
		var next: Variant = definition[key]
		var tag := "%s.%s" % [prev_tag, key]

		if not r_identifiers.has(key):
			r_identifiers.push_back(key)

		match typeof(next):
			TYPE_STRING, TYPE_STRING:
				var comment: String = next
				if not comment.is_empty():
					ret += "\t## %s\n" % comment
				ret += "\t%s = &\"%s\",\n" % [key, tag]
			TYPE_DICTIONARY:
				ret += "\t%s = {\n" % key
				ret += _generate_tag_text_recursively(next, tag, r_identifiers, depth + 1)
				ret += "\t},\n"
	for i in range(depth):
		ret = ret.indent("\t")
	return ret
#endregion Generate
