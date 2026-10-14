extends Control
## 存档选择场景：新建存档（名称 / 玩家数量 / 终点分数），或选择已有存档进入游戏。

const UiStyle := preload("res://scripts/ui_style.gd")

const VIEW_W := 1280.0
const VIEW_H := 800.0
const MARGIN := 40.0
const HUD_Y := 16.0
const HUD_H := 38.0
const HUD_GAP := 8.0
const HUD_LANG_W := 100.0
const HUD_SOUND_W := 136.0
const PANEL_TOP := 100.0
const PANEL_H := 566.0

var _title_label: Label
var _lang_button: Button
var _mute_button: Button
var _clear_button: Button
var _form_title: Label
var _list_title: Label
var _name_edit: LineEdit
var _create_button: Button
var _list_box: VBoxContainer
var _confirm: Control

var _field_labels: Dictionary = {}                 # 翻译 key -> Label
var _form_values: Dictionary = {"players": 8, "target": 20}
var _stepper_bounds: Dictionary = {}
var _stepper_labels: Dictionary = {}


func _ready() -> void:
	I18n.locale_changed.connect(_on_locale_changed)
	_build_header()
	_build_form()
	_build_list()
	_build_footer()
	_refresh_list()
	queue_redraw()


func _draw() -> void:
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(VIEW_W, 0), Vector2(VIEW_W, VIEW_H), Vector2(0, VIEW_H)]),
		PackedColorArray([
			Color(0.11, 0.42, 0.66), Color(0.11, 0.42, 0.66),
			Color(0.02, 0.10, 0.18), Color(0.02, 0.10, 0.18)
		])
	)


# ——————————————————— 顶部 ———————————————————

func _build_header() -> void:
	_title_label = Label.new()
	_title_label.text = I18n.t("SAVE_SELECT_TITLE")
	_title_label.position = Vector2(0, 22)
	_title_label.size = Vector2(VIEW_W, 38)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 28)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0))
	_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.45))
	_title_label.add_theme_constant_override("outline_size", 4)
	add_child(_title_label)

	var right := VIEW_W - MARGIN
	var mute_x := right - HUD_SOUND_W
	var lang_x := mute_x - HUD_GAP - HUD_LANG_W

	_lang_button = Button.new()
	_lang_button.focus_mode = Control.FOCUS_NONE
	_lang_button.text = I18n.switch_button_text()
	_lang_button.position = Vector2(lang_x, HUD_Y)
	_lang_button.size = Vector2(HUD_LANG_W, HUD_H)
	_lang_button.add_theme_font_size_override("font_size", 15)
	UiStyle.hud_button(_lang_button, false, Color(0.55, 0.85, 0.65, 0.70))
	_lang_button.pressed.connect(func() -> void: I18n.toggle())
	add_child(_lang_button)

	_mute_button = Button.new()
	_mute_button.toggle_mode = true
	_mute_button.focus_mode = Control.FOCUS_NONE
	_mute_button.position = Vector2(mute_x, HUD_Y)
	_mute_button.size = Vector2(HUD_SOUND_W, HUD_H)
	_mute_button.add_theme_font_size_override("font_size", 16)
	UiStyle.hud_button(_mute_button)
	_mute_button.button_pressed = SoundManager.is_muted()
	_update_mute_text()
	_mute_button.toggled.connect(_on_mute_toggled)
	add_child(_mute_button)


func _update_mute_text() -> void:
	_mute_button.text = I18n.t("BTN_SOUND_OFF" if _mute_button.button_pressed else "BTN_SOUND_ON")


func _on_mute_toggled(pressed: bool) -> void:
	SoundManager.set_muted(pressed)
	_update_mute_text()


# ——————————————————— 新建存档表单 ———————————————————

func _build_form() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(MARGIN, PANEL_TOP)
	panel.size = Vector2(560.0, PANEL_H)
	panel.add_theme_stylebox_override("panel", UiStyle.card_style())
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	panel.add_child(vb)

	_form_title = _make_label(vb, "NEW_SAVE_TITLE", 23, Color(0.85, 0.95, 1.0))

	_make_label(vb, "SAVE_NAME_LABEL", 16, Color(0.78, 0.88, 0.98))
	_name_edit = LineEdit.new()
	_name_edit.custom_minimum_size = Vector2(0, 46)
	_name_edit.max_length = DataStore.SLOT_NAME_MAX_LEN
	_name_edit.add_theme_font_size_override("font_size", 18)
	_name_edit.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0))
	_name_edit.add_theme_color_override("font_placeholder_color", Color(0.7, 0.8, 0.9, 0.5))
	var edit_style := StyleBoxFlat.new()
	edit_style.bg_color = Color(1, 1, 1, 0.10)
	edit_style.set_corner_radius_all(8)
	edit_style.set_content_margin_all(8)
	_name_edit.add_theme_stylebox_override("normal", edit_style)
	var edit_focus: StyleBoxFlat = edit_style.duplicate()
	edit_focus.bg_color = Color(1, 1, 1, 0.16)
	edit_focus.border_width_bottom = 2
	edit_focus.border_color = Color(0.45, 0.75, 1.0)
	_name_edit.add_theme_stylebox_override("focus", edit_focus)
	vb.add_child(_name_edit)

	_make_stepper(vb, "players", "PLAYER_COUNT_LABEL", DataStore.PLAYER_MIN, DataStore.PLAYER_MAX)
	_make_stepper(vb, "target", "TARGET_SCORE_LABEL", DataStore.TARGET_MIN, DataStore.TARGET_MAX)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(spacer)

	_create_button = Button.new()
	_create_button.text = I18n.t("BTN_CREATE_START")
	_create_button.custom_minimum_size = Vector2(0, 52)
	_create_button.add_theme_font_size_override("font_size", 20)
	UiStyle.filled_button(_create_button, Color(0.18, 0.60, 0.42))
	_create_button.pressed.connect(_on_create_pressed)
	vb.add_child(_create_button)


func _make_label(parent: Node, key: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = I18n.t(key)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	_field_labels[key] = label
	return label


func _make_stepper(parent: Node, key: String, title_key: String, min_v: int, max_v: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)

	var title := _make_label(row, title_key, 16, Color(0.78, 0.88, 0.98))
	title.custom_minimum_size = Vector2(120, 44)
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var minus := _step_button("−")
	minus.pressed.connect(_on_stepper.bind(key, -1))
	row.add_child(minus)

	var value := Label.new()
	value.custom_minimum_size = Vector2(90, 44)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size", 24)
	value.add_theme_color_override("font_color", Color(0.88, 0.96, 1.0))
	row.add_child(value)

	var plus := _step_button("+")
	plus.pressed.connect(_on_stepper.bind(key, 1))
	row.add_child(plus)

	_stepper_labels[key] = value
	_stepper_bounds[key] = Vector2i(min_v, max_v)
	_refresh_stepper(key)


func _step_button(text_value: String) -> Button:
	var btn := Button.new()
	btn.text = text_value
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(54, 44)
	btn.add_theme_font_size_override("font_size", 22)
	UiStyle.hud_button(btn)
	return btn


func _on_stepper(key: String, delta: int) -> void:
	var bounds: Vector2i = _stepper_bounds[key]
	var next_value := clampi(int(_form_values[key]) + delta, bounds.x, bounds.y)
	if next_value == int(_form_values[key]):
		SoundManager.play_denied()
		return
	_form_values[key] = next_value
	SoundManager.play_click()
	_refresh_stepper(key)


func _refresh_stepper(key: String) -> void:
	var label: Label = _stepper_labels.get(key)
	if label:
		label.text = str(_form_values[key])


func _on_create_pressed() -> void:
	var slot_name := _name_edit.text.strip_edges()
	if slot_name.is_empty():
		slot_name = _default_slot_name()
	var id := DataStore.create_slot(slot_name, int(_form_values["players"]), int(_form_values["target"]))
	if id.is_empty():
		SoundManager.play_denied()
		return
	SoundManager.play_up()
	_enter_game()


func _default_slot_name() -> String:
	return I18n.t("SAVE_NAME_PLACEHOLDER", [DataStore.get_slot_count() + 1])


# ——————————————————— 存档列表 ———————————————————

func _build_list() -> void:
	var panel := PanelContainer.new()
	panel.position = Vector2(628.0, PANEL_TOP)
	panel.size = Vector2(VIEW_W - 628.0 - MARGIN, PANEL_H)
	panel.add_theme_stylebox_override("panel", UiStyle.card_style())
	add_child(panel)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	panel.add_child(vb)

	_list_title = _make_label(vb, "SAVE_LIST_TITLE", 23, Color(0.85, 0.95, 1.0))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vb.add_child(scroll)

	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_box)


func _refresh_list() -> void:
	for child in _list_box.get_children():
		child.queue_free()
	_name_edit.placeholder_text = _default_slot_name()

	var slots := DataStore.get_slot_summaries()
	if slots.is_empty():
		var empty := Label.new()
		empty.text = I18n.t("NO_SAVES")
		empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty.add_theme_font_size_override("font_size", 15)
		empty.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95, 0.75))
		_list_box.add_child(empty)
		return
	for slot in slots:
		_list_box.add_child(_make_slot_row(slot))


func _make_slot_row(slot: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiStyle.card_style(
		Color(0.07, 0.16, 0.28, 0.95), Color(0.35, 0.60, 0.90, 0.45), 14, 2, 14
	))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)

	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 3)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(info)

	var slot_name := str(slot.get("name", ""))
	if slot_name.is_empty():
		slot_name = I18n.t("SAVE_NAME_PLACEHOLDER", [1])

	var name_label := Label.new()
	name_label.text = slot_name
	name_label.add_theme_font_size_override("font_size", 19)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.99, 1.0))
	info.add_child(name_label)

	var meta := Label.new()
	meta.text = I18n.t("SLOT_META", [int(slot["player_count"]), int(slot["max_score"]), int(slot["matches_played"])])
	meta.add_theme_font_size_override("font_size", 13)
	meta.add_theme_color_override("font_color", Color(0.70, 0.83, 0.95, 0.85))
	info.add_child(meta)

	var updated := Label.new()
	updated.text = I18n.t("SLOT_UPDATED", [str(slot.get("updated_at", ""))])
	updated.add_theme_font_size_override("font_size", 12)
	updated.add_theme_color_override("font_color", Color(0.60, 0.72, 0.85, 0.70))
	info.add_child(updated)

	var enter := Button.new()
	enter.text = I18n.t("BTN_ENTER")
	enter.focus_mode = Control.FOCUS_NONE
	enter.custom_minimum_size = Vector2(92, 48)
	enter.add_theme_font_size_override("font_size", 17)
	UiStyle.filled_button(enter, Color(0.20, 0.55, 0.85))
	enter.pressed.connect(_on_enter_slot.bind(str(slot["id"])))
	row.add_child(enter)

	var del := Button.new()
	del.text = I18n.t("BTN_DELETE")
	del.focus_mode = Control.FOCUS_NONE
	del.custom_minimum_size = Vector2(92, 48)
	del.add_theme_font_size_override("font_size", 17)
	UiStyle.filled_button(del, Color(0.62, 0.26, 0.28))
	del.pressed.connect(_on_delete_slot.bind(str(slot["id"]), slot_name))
	row.add_child(del)

	return card


func _on_enter_slot(id: String) -> void:
	if not DataStore.set_active_slot(id):
		SoundManager.play_denied()
		return
	SoundManager.play_up()
	_enter_game()


func _on_delete_slot(id: String, slot_name: String) -> void:
	_close_confirm()
	_confirm = UiStyle.confirm_dialog(
		self,
		I18n.t("DELETE_SLOT_TITLE"),
		I18n.t("DELETE_SLOT_BODY", [slot_name]),
		I18n.t("BTN_CANCEL"),
		I18n.t("BTN_DELETE"),
		_on_delete_confirmed.bind(id)
	)


func _on_delete_confirmed(id: String) -> void:
	_confirm = null
	DataStore.delete_slot(id)
	SoundManager.play_down()
	_refresh_list()


# ——————————————————— 底部：清空全部数据 ———————————————————

func _build_footer() -> void:
	_clear_button = Button.new()
	_clear_button.text = I18n.t("CLEAR_ALL_TITLE")
	_clear_button.focus_mode = Control.FOCUS_NONE
	_clear_button.position = Vector2(VIEW_W - MARGIN - 220.0, VIEW_H - MARGIN - 44.0)
	_clear_button.size = Vector2(220.0, 44.0)
	_clear_button.add_theme_font_size_override("font_size", 16)
	UiStyle.hud_button(_clear_button, true)
	_clear_button.pressed.connect(_on_clear_all_pressed)
	add_child(_clear_button)


func _on_clear_all_pressed() -> void:
	_close_confirm()
	_confirm = UiStyle.confirm_dialog(
		self,
		I18n.t("CLEAR_ALL_TITLE"),
		I18n.t("CLEAR_ALL_BODY"),
		I18n.t("BTN_CANCEL"),
		I18n.t("BTN_CONFIRM_RESET"),
		_on_clear_all_confirmed
	)


func _on_clear_all_confirmed() -> void:
	_confirm = null
	DataStore.clear_all()
	SoundManager.reload_settings()
	I18n.reload_settings()
	_refresh_list()


func _close_confirm() -> void:
	if _confirm and is_instance_valid(_confirm):
		_confirm.queue_free()
	_confirm = null


# ——————————————————— 通用 ———————————————————

func _enter_game() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


func _refresh_texts() -> void:
	_title_label.text = I18n.t("SAVE_SELECT_TITLE")
	_lang_button.text = I18n.switch_button_text()
	_update_mute_text()
	_form_title.text = I18n.t("NEW_SAVE_TITLE")
	_list_title.text = I18n.t("SAVE_LIST_TITLE")
	for key in _field_labels:
		(_field_labels[key] as Label).text = I18n.t(key)
	_create_button.text = I18n.t("BTN_CREATE_START")
	_clear_button.text = I18n.t("CLEAR_ALL_TITLE")
	_close_confirm()
	_refresh_list()
