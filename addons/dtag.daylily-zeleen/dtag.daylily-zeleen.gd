@tool
extends EditorPlugin

# Use const Map 

class EditorInspectorPluginTag extends EditorInspectorPlugin:
	var _selector: Window
	func _init(selector: Window) -> void:
		_selector = selector

	func _can_handle(object) -> bool:
		return true

	func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: PropertyUsageFlags, wide: bool) -> bool:
		const TAG_EDIT_PREFIX := "DTagEdit"
		const TAG_DOMAIN_EDIT_PREFIX := "DTagDomainEdit"
		var select_tag := hint_string.begins_with(TAG_EDIT_PREFIX)
		var select_domain := hint_string.begins_with(TAG_DOMAIN_EDIT_PREFIX)
		if type in [TYPE_STRING, TYPE_STRING_NAME, TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY]:
			if select_tag:
				var splits := hint_string.split(":", false, 1)
				var domain := [] if splits.size() < 2 else (splits[1].strip_edges(true).split(".", false))
				var prop_edit := preload("editor/edit_property_dtag.gd").new()
				prop_edit.setup(domain, true, _selector)
				add_property_editor(name, prop_edit)
				return true
			elif select_domain:
				var prop_edit := preload("editor/edit_property_dtag.gd").new()
				prop_edit.setup([], false, _selector)
				add_property_editor(name, prop_edit)
				return true
		return false

var _selector :Window
var _inspector_plugin : EditorInspectorPluginTag
var _highlighter := preload("editor/dtag_syntax_highlighter.gd").new()

const ESETTING_TEXTFILE_EXTENDSIONS := "docks/filesystem/textfile_extensions"
const OVERRIDE_SETTING_TEXTFILE_EXTENDSIONS := "editor_overrides/docks/filesystem/textfile_extensions"

func _enter_tree() -> void:
	if not ProjectSettings.has_setting(OVERRIDE_SETTING_TEXTFILE_EXTENDSIONS):
		ProjectSettings.set_setting(OVERRIDE_SETTING_TEXTFILE_EXTENDSIONS, EditorInterface.get_editor_settings().get_setting(ESETTING_TEXTFILE_EXTENDSIONS))

	var extensions := ProjectSettings.get_setting_with_override(OVERRIDE_SETTING_TEXTFILE_EXTENDSIONS) as String
	var valid := false
	for e in extensions.split(","):
		if e.strip_edges() == "dtag":
			valid = true
			break
	if not valid :
		extensions += ",dtag"
	ProjectSettings.set_setting(OVERRIDE_SETTING_TEXTFILE_EXTENDSIONS, extensions)
	
	_selector = preload("editor/dtag_selector.tscn").instantiate()
	add_child(_selector)
	
	_inspector_plugin = EditorInspectorPluginTag.new(_selector)
	add_inspector_plugin(_inspector_plugin)

	add_tool_menu_item("Generate dtag_def.gen.gd", _on_generate_dtag_def_gen_requested)

	EditorInterface.get_script_editor().register_syntax_highlighter(_highlighter)

func _exit_tree() -> void:
	remove_inspector_plugin(_inspector_plugin)

	remove_tool_menu_item("Generate dtag_def.gen.gd")

	EditorInterface.get_script_editor().unregister_syntax_highlighter(_highlighter)


func _on_generate_dtag_def_gen_requested() -> void:
	var tool := preload("tool/tool_generate_dtag.gd").new() as EditorScript
	tool._run()
