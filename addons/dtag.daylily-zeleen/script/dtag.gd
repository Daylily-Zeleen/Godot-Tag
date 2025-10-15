@tool
@static_unload
class_name DTag
extends Resource

var scopes: Array[StringName]
var tag :StringName


func _get_property_list() -> Array[Dictionary]:
	var ret :Array[Dictionary] = [
		{
			name = &"tag",
			type = TYPE_STRING_NAME,
			hint = PROPERTY_HINT_NONE,
			hint_string = "DTagEdit:" % ".".join(scopes),
			usage = PROPERTY_USAGE_DEFAULT,
		},
		{
			name = &"scopes",
			type = TYPE_ARRAY,
			hint = PROPERTY_HINT_NONE,
			hint_string = "DTagScopesEdit",
			usage = PROPERTY_USAGE_DEFAULT,
		}
	]
	return ret


func _get(property: StringName) -> Variant:
	match property:
		&"scopes":
			return scopes
		&"tag":
			return tag
		_:
			return null


func _set(property: StringName, value: Variant) -> bool:
	match property:
		&"tag":
			if scopes.is_empty():
				tag = value
				scopes = Array(tag.split(".", false), TYPE_STRING_NAME, &"", null)
				notify_property_list_changed()
			else:
				if Engine.is_editor_hint():
					# Validate in editor
					var splits := value.split(".", false) as PackedStringArray
					var valid := true
					for i in range(mini(scopes.size(), splits.size())):
						if scopes[i] != splits[i]:
							valid = false
							break

					if valid:
						tag = value
						notify_property_list_changed()
				else:
					tag = value

			return true
		&"scopes":
			scopes = value
			if Engine.is_editor_hint() and not tag.is_empty():
				if not is_scopes_match(tag):
					print_rich("[color=yellow][WARN] DTag: \"%s\" tag is incompatible with scopes \"%s\", will be reset to &\"\".[/color]" % [tag, ".".join(scopes)])
					tag = &""
			notify_property_list_changed()
			return true
		_:
			return false


func is_equal(other_tag: Variant) -> bool:
	assert(other_tag is DTag or other_tag is StringName)
	if other_tag is DTag:
		return tag == other_tag.tag
	elif other_tag is StringName or other_tag is String:
		return tag == other_tag

	assert(false, "Unrecognize type")
	return false


func is_scopes_match(other_scopes: Variant) -> bool:
	if other_scopes is DTag:
		for i in range(mini(other_scopes.scopes.size(), scopes.size())):
			if other_scopes.scopes[i] != scopes[i]:
				return false
		return true
	elif other_scopes is StringName or other_scopes is String:
		var splits := other_scopes.split(".", false) as PackedStringArray
		for i in range(mini(splits.size(), scopes.size())):
			if splits[i] != scopes[i]:
				return false
		return true
	elif typeof(other_scopes) >= TYPE_ARRAY:
		for i in range(mini(other_scopes.size(), scopes.size())):
			if other_scopes[i] != scopes[i]:
				return false
		return true

	assert(false, "Unrecognize type")
	return false


static var _tag_cache: Dictionary[StringName, DTag]
static func from(p_tag: StringName) -> DTag:
	if Engine.is_editor_hint():
		var ret := DTag.new()
		ret.tag = p_tag
		return ret
	else:
		if _tag_cache.has(p_tag):
			return _tag_cache.get(p_tag)
		var ret := DTag.new()
		ret.tag = p_tag
		_tag_cache[p_tag] = ret
		return ret


static var _scopes_cache: Dictionary[StringName, DTag]
static func as_scopes(p_scopes: StringName) -> DTag:
	if Engine.is_editor_hint():
		var ret := DTag.new()
		ret.scopes = p_scopes.split(".", false)
		return ret
	else:
		if _scopes_cache.has(p_scopes):
			return _scopes_cache.get(p_scopes)
		var ret := DTag.new()
		ret.scopes = p_scopes.split(".", false)
		_scopes_cache[p_scopes] = ret
		return ret
