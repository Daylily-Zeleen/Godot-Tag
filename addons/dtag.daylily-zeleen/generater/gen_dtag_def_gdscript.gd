@tool

const Parser := preload("../editor/parser.gd")
const DomainDef := Parser.DomainDef
const TagDef := Parser.TagDef

const DOMAIN_NAME := "DOMAIN_NAME"
const GEN_FILE := "res://dtag_def.gen.gd"

func generate(parse_result: Dictionary[String, RefCounted], redirect_map: Dictionary[String, String]) -> String:
	var fa := FileAccess.open(GEN_FILE, FileAccess.WRITE)
	if not is_instance_valid(fa):
		printerr("[DTag] Generate \"%s\" failed: %s" % [GEN_FILE, error_string(FileAccess.get_open_error())])
		return ""

	var identifiers: PackedStringArray
	var text := "# NOTE: This file is generated, any modify maybe discard.\n"
	text += "class_name DTagDef\n\n"

	for def in parse_result.values():
		if def is TagDef:
			text += "\n"
			if not def.desc.is_empty():
				text += "## " + def.desc
			text += "const %s = %s" % [def.name, def.redirect if not def.redirect.is_empty() else def.name]
			text += "\n"

			if not identifiers.has(def.name):
				identifiers.push_back(def.name)

	for def in parse_result.values():
		if def is DomainDef:
			if not identifiers.has(def.name):
				identifiers.push_back(def.name)

			text += "\n"
			if not def.desc.is_empty():
				text += "## %s\n" % def.desc
			text += "const %s = {\n" % def.name
			text += "\t%s = &\"%s\",\n" % [DOMAIN_NAME, def.name if def.redirect.is_empty() else def.redirect]
			text += _generate_text_recursively(def, def.name, identifiers)
			text += "}\n"

	if not redirect_map.is_empty():
		text += "\n\nconst _REDIRECT_NAP: Dictionary[StringName, StringName] = {\n"
		for k in redirect_map:
			var redirected := redirect_map[k]
			while redirect_map.has(redirected):
				var next := redirect_map[redirected]
				if next == k:
					printerr("[DTag] Cycle redirect %s." % k)
					break
				redirected = next
			text += '\t&"%s" : &"%s",\n' % [k, redirect_map[k]]
		text += "}\n"

	fa.store_string(text)
	fa.close()

	var opened_scripts := EditorInterface.get_script_editor().get_open_scripts()
	for i in range(opened_scripts.size()):
		var script := opened_scripts[i] as Script
		if script.resource_path == GEN_FILE:
			var se := EditorInterface.get_script_editor().get_open_script_editors().get(i) as ScriptEditorBase
			if is_instance_valid(se):
				var te := se.get_base_editor() as CodeEdit
				if is_instance_valid(te):
					te.text = text
					te.tag_saved_version()
			break

	print("[DTag]: \"%s\" is generated." % [GEN_FILE])
	return GEN_FILE


#region Generate
static func _generate_text_recursively(def: DomainDef, prev_tag: String, r_identifiers: PackedStringArray, depth := 0) -> String:
	var ret := ""
	for tag: TagDef in def.tag_list.values():
		var tag_text := ("%s.%s" % [prev_tag, tag.name]) if tag.redirect.is_empty() else tag.redirect
		if not tag.desc.is_empty():
			ret += "\t## %s\n" %[tag.desc]
		ret += "\t%s = &\"%s\",\n" % [tag.name, tag_text]

	for domain: DomainDef in def.sub_domain_list.values():
		var tag_text := ("%s.%s" % [prev_tag, domain.name]) if domain.redirect.is_empty() else domain.redirect
		if not domain.desc.is_empty():
			ret += "\t## %s\n" % domain.desc
		ret += "\t%s = {\n" %domain.name
		ret += "\t\t%s = &\"%s\",\n" % [DOMAIN_NAME, tag_text]
		ret += _generate_text_recursively(domain, tag_text, r_identifiers, depth + 1)
		ret += "\t},\n"

	for i in range(depth):
		ret = ret.indent("\t")
	return ret
#endregion Generate
