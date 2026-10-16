extends PanelContainer
class_name ControlPanel
## 底部操作面板：玩家头像色块、名称、实时分数、+/- 按钮。

signal score_requested(racer_index: int, delta: int)
signal name_changed(racer_index: int, new_name: String)

var racer_index: int = 0
var racer_color: Color = Color.WHITE
var racer_name: String = ""
var max_score: int = 20

var _score_label: Label
var _plus_button: Button
var _minus_button: Button
var _name_edit: LineEdit
var _wins_label: Label
var _wins_value: int = 0


## 必须在加入场景树（add_child）之前调用。
func setup(p_index: int, p_color: Color, p_name: String, p_max: int) -> void:
	racer_index = p_index
	racer_color = p_color
	racer_name = p_name
	max_score = p_max


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.11, 0.21, 0.9)
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.border_color = racer_color
	style.set_content_margin_all(8)
	add_theme_stylebox_override("panel", style)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	add_child(vb)

	# 头部：颜色头像 + 玩家名称
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6)
	vb.add_child(head)

	var swatch := ColorRect.new()
	swatch.color = racer_color
	swatch.custom_minimum_size = Vector2(18, 18)
	head.add_child(swatch)

	# 可编辑的玩家名称（点击即可修改，回车或失焦生效）
	_name_edit = LineEdit.new()
	_name_edit.text = racer_name
	_name_edit.placeholder_text = I18n.t("NAME_PLACEHOLDER")
	_name_edit.max_length = 12
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.add_theme_font_size_override("font_size", 15)
	_name_edit.add_theme_color_override("font_color", Color(0.93, 0.97, 1.0))
	_name_edit.add_theme_color_override("font_placeholder_color", Color(0.7, 0.8, 0.9, 0.5))
	var name_normal := StyleBoxFlat.new()
	name_normal.bg_color = Color(1, 1, 1, 0.0)
	name_normal.set_corner_radius_all(6)
	name_normal.content_margin_left = 5
	name_normal.content_margin_right = 5
	name_normal.content_margin_top = 2
	name_normal.content_margin_bottom = 2
	_name_edit.add_theme_stylebox_override("normal", name_normal)
	var name_focus: StyleBoxFlat = name_normal.duplicate()
	name_focus.bg_color = Color(1, 1, 1, 0.14)
	name_focus.border_width_bottom = 2
	name_focus.border_color = racer_color
	_name_edit.add_theme_stylebox_override("focus", name_focus)
	_name_edit.text_submitted.connect(_on_name_submitted)
	_name_edit.focus_exited.connect(_on_name_focus_exited)
	head.add_child(_name_edit)

	# 累计胜场徽标（无胜场时隐藏）
	_wins_label = Label.new()
	_wins_label.add_theme_font_size_override("font_size", 12)
	_wins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40))
	_wins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_wins_label.visible = false
	head.add_child(_wins_label)

	# 实时分数
	_score_label = Label.new()
	_score_label.text = "0/%d" % max_score
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 26)
	_score_label.add_theme_color_override("font_color", racer_color.lightened(0.35))
	_score_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_score_label)

	# +/- 按钮
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	vb.add_child(row)

	_minus_button = _make_button("-", Color(0.85, 0.30, 0.30))
	_minus_button.pressed.connect(_on_minus_pressed)
	row.add_child(_minus_button)

	_plus_button = _make_button("+", Color(0.25, 0.75, 0.42))
	_plus_button.pressed.connect(_on_plus_pressed)
	row.add_child(_plus_button)


func _make_button(text_value: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(0, 52)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", Color(1, 1, 1))
	b.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	b.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.35))

	var normal := StyleBoxFlat.new()
	normal.bg_color = color
	normal.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", normal)

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = color.lightened(0.16)
	b.add_theme_stylebox_override("hover", hover)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = color.darkened(0.2)
	b.add_theme_stylebox_override("pressed", pressed)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.3, 0.3, 0.3, 0.6)
	b.add_theme_stylebox_override("disabled", disabled)

	return b


func set_score(value: int) -> void:
	_score_label.text = "%d/%d" % [value, max_score]
	# 数字跳动反馈
	_score_label.pivot_offset = _score_label.size * 0.5
	var tween := create_tween()
	_score_label.scale = Vector2(1.35, 1.35)
	tween.tween_property(_score_label, "scale", Vector2.ONE, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_buttons_enabled(enabled: bool) -> void:
	_plus_button.disabled = not enabled
	_minus_button.disabled = not enabled
	# 已获胜的玩家面板整体锁定（名称也不允许再改）
	if _name_edit:
		_name_edit.editable = enabled


## 由主场景回写（用于清洗后的最终名称）。
func set_name_text(value: String) -> void:
	if _name_edit and _name_edit.text != value:
		_name_edit.text = value


## 显示累计胜场数。
func set_wins(value: int) -> void:
	_wins_value = value
	_refresh_wins()


## 语言切换后刷新本面板的文案（名称由主场景负责）。
func refresh_texts() -> void:
	if _name_edit:
		_name_edit.placeholder_text = I18n.t("NAME_PLACEHOLDER")
	_refresh_wins()


func _refresh_wins() -> void:
	if _wins_label == null:
		return
	_wins_label.text = I18n.t("STATUS_WINS", [_wins_value])
	_wins_label.visible = _wins_value > 0


func _on_name_submitted(_new_text: String) -> void:
	_commit_name()


func _on_name_focus_exited() -> void:
	_commit_name()


func _commit_name() -> void:
	name_changed.emit(racer_index, _name_edit.text.strip_edges())


func _on_plus_pressed() -> void:
	score_requested.emit(racer_index, 1)


func _on_minus_pressed() -> void:
	score_requested.emit(racer_index, -1)
