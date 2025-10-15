@tool
extends EditorProperty

var _scopes :PackedStringArray

var _tag_button := Button.new()

var _select_tag: bool
var _selector: Window

func _init() -> void:
	_tag_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tag_button.text_overrun_behavior = TextServer.OVERRUN_TRIM_CHAR
	_tag_button.pressed.connect(_on_tag_button_pressed)
	add_child(_tag_button)


func setup(scopes: PackedStringArray, select_tag: bool, selector: Window) -> void:
	_scopes = scopes
	_select_tag = select_tag
	_selector = selector


func _set_read_only(read_only: bool) -> void:
	_tag_button.disabled = read_only


func _update_property() -> void:
	var obj := get_edited_object()
	var prop := get_edited_property()
	var v := obj.get(prop)

	if typeof(v) in [TYPE_STRING, TYPE_STRING_NAME]:
		_tag_button.text = v
	elif v is Array or v is PackedStringArray:
		_tag_button.text = ".".join(v)

	_tag_button.tooltip_text = _tag_button.text
	printerr(_tag_button.text)


func _on_tag_button_pressed() -> void:
	var obj := get_edited_object()
	var prop := get_edited_property()
	var v := obj.get(prop)

	if typeof(v) in [TYPE_STRING, TYPE_STRING_NAME]:
		_selector.setup(v, [], _select_tag)
	elif typeof(v) in [TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY]:
		_selector.setup(&"", _scopes, _select_tag)
	else:
		assert(false)
		return

	var result := await _selector.selected as Array
	var selected := result[0] as StringName
	var confirm := result[1] as bool

	if confirm:
		if typeof(v) in [TYPE_STRING, TYPE_STRING_NAME]:
			emit_changed(prop, selected)
		else:
			emit_changed(prop, selected.split(".", false))
