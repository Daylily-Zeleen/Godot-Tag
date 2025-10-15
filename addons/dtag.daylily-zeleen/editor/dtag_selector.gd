@tool
extends ConfirmationDialog

signal selected(tag_or_scopes :StringName, confirm: bool)

@export_group("_internal_", "_")
@export var _search_line_edit: LineEdit
@export var _selected_label: Label
@export var _tree: Tree

var _selected: StringName = &"":
	set(v):
		_selected = v
		_selected_label.text = _selected
		get_ok_button().disabled = _selected.is_empty()
var _scopes_limitation: StringName
var _select_tag:bool

var _leaves_item:Array[TreeItem]


func _ready() -> void:
	hide()
	confirmed.connect(_on_confirmed)
	_search_line_edit.text_changed.connect(_on_search_text_changed)
	_tree.item_activated.connect(_on_tree_item_activated)
	_tree.item_selected.connect(_on_tree_item_selected)


func setup(tag: StringName, scopes: PackedStringArray, select_tag: bool) -> void:
	if select_tag:
		_selected = tag
		title = "Select DTag"
	else:
		_selected = ".".join(scopes)
		title = "Select DTag Scope"

	_scopes_limitation = (".".join(scopes) + ".") if not scopes.is_empty() else ""
	_select_tag = select_tag

	_leaves_item.clear()
	_tree.clear()
	var root := _tree.create_item()
	root.set_text(0, "")
	root.set_metadata(0, "")
	root.set_tooltip_text(0, "")

	const DEF_CLASS := &"DTagDef"
	var def_class_path :String = ""
	for class_info in ProjectSettings.get_global_class_list():
		if class_info.class == DEF_CLASS:
			def_class_path = class_info.path

	if not def_class_path.is_empty():
		var def_script := load(def_class_path) as Script
		var const_map := def_script.get_script_constant_map()
		for k in const_map:
			var def :Variant = const_map[k]
			if not def is Dictionary:
				continue

			if not _scopes_limitation.is_empty() and not _scopes_limitation.begins_with(k + "."):
				# 过滤命名空间限制
				continue

			var item := root.create_child()
			item.set_text(0, k)
			item.set_metadata(0, k)
			item.set_tooltip_text(0, k)
			_setup_item_recursively(item, def)

	_on_search_text_changed(_search_line_edit.text)
	popup_centered_ratio(0.6)


func _setup_item_recursively(parent: TreeItem, def: Dictionary) -> void:
	var prev_scopes := parent.get_metadata(0) as String
	for k: String in def:
		var next_def :Variant = def[k]
		var tag := prev_scopes + "." + k
		if not _scopes_limitation.is_empty() and not _scopes_limitation.begins_with(tag + "."):
			# 过滤命名空间限制
			continue

		var item := parent.create_child()
		item.set_text(0, k)
		item.set_metadata(0, tag)
		item.set_tooltip_text(0, tag)

		if next_def is Dictionary:
			_setup_item_recursively(item, next_def)
			if _select_tag:
				item.set_selectable(0, false)
		else:
			if not _select_tag:
				item.set_selectable(0, false)

		if item.get_child_count() <= 0:
			_leaves_item.push_back(item)


func _update_parent_item_visible_recursively(item: TreeItem) -> void:
	var parent := item.get_parent()
	if parent == _tree.get_root():
		return

	var parent_visible := false
	for c in parent.get_children():
		if c.visible:
			parent_visible = true

	parent.visible = parent_visible
	_update_parent_item_visible_recursively(parent)


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible:
			selected.emit(&"", false)


func _on_search_text_changed(search_text: String) -> void:
	for item in _leaves_item:
		var tag := item.get_metadata(0) as StringName
		item.visible = tag.contains(search_text) if not search_text.is_empty() else true

	for item in _leaves_item:
		_update_parent_item_visible_recursively(item)


func _on_confirmed() -> void:
	if not _selected.is_empty():
		selected.emit(_selected, true)
		hide()


func _on_tree_item_activated() -> void:
	selected.emit(_selected, true)
	hide()


func _on_tree_item_selected() -> void:
	_selected = _tree.get_selected().get_metadata(0)
