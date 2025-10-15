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
		const TAG_EDIT_PREFIX := "DTagEdit:"
		const TAG_SCOPE_EDIT_PREFIX := "DTagScopesEdit"
		var select_tag := hint_string.begins_with(TAG_EDIT_PREFIX)
		var select_scope := hint_string.begins_with(TAG_SCOPE_EDIT_PREFIX)
		if type in [TYPE_STRING, TYPE_STRING_NAME]:
			if hint_string.begins_with(TAG_EDIT_PREFIX):
				var scopes := hint_string.trim_prefix(TAG_EDIT_PREFIX).split(".", false)
				var prop_edit := preload("res://addons/dtag.daylily-zeleen/editor/edit_property_dtag.gd").new()
				prop_edit.setup(scopes, true, _selector)
				add_property_editor(name, prop_edit)
				return true
		return false

var _selector :Window
var _inspector_plugin : EditorInspectorPluginTag

func _enter_tree() -> void:
	_selector = preload("res://addons/dtag.daylily-zeleen/editor/dtag_selector.tscn").instantiate()
	add_child(_selector)
	
	_inspector_plugin = EditorInspectorPluginTag.new(_selector)
	add_inspector_plugin(_inspector_plugin)


func _exit_tree() -> void:
	remove_inspector_plugin(_inspector_plugin)
