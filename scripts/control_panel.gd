extends PanelContainer
class_name ControlPanel
## 底部操作面板：玩家头像色块、玩家名称、实时分数、+/- 按钮。

const UiStyle := preload("res://scripts/ui_style.gd")

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
var _compact: bool = false   ## 紧凑模式：人数多、底部每格偏窄时启用

# 名称框最小宽度：紧凑时更窄（两者都必须足够小，否则会被文字宽撑宽而溢出）
const NAME_EDIT_MIN_W := 20.0
const NAME_EDIT_MIN_W_NARROW := 16.0


## 必须在加入场景树（add_child）之前调用。
func setup(p_index: int, p_color: Color, p_name: String, p_max: int, p_compact: bool = false) -> void:
	racer_index = p_index
	racer_color = p_color
	racer_name = p_name
	max_score = p_max
	_compact = p_compact


func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.11, 0.21, 0.9)
	style.set_corner_radius_all(14 if not _compact else 10)
	style.set_border_width_all(2)
	style.border_color = racer_color
	style.set_content_margin_all(8.0 if not _compact else 5.0)
	add_theme_stylebox_override("panel", style)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6 if not _compact else 3)
	add_child(vb)

	# 头部：颜色头像 + 玩家名称
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 6 if not _compact else 4)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_child(head)

	var swatch := ColorRect.new()
	swatch.color = racer_color
	swatch.custom_minimum_size = Vector2(18, 18) if not _compact else Vector2(14, 14)
	swatch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	head.add_child(swatch)

	# 可编辑的玩家名称（点击即可修改，回车或失焦生效）
	# 注意：LineEdit 的最小宽会被 text / placeholder_text 的像素宽度撑大（取 max），
	# 12 人时 "Player 10" ≈ 71px 足以把面板撞宽、顶出横向滚动条；
	# 因此固定最小宽，并把占位文字换成极短的 "·"。
	_name_edit = LineEdit.new()
	_name_edit.text = racer_name
	_name_edit.placeholder_text = "·"
	_name_edit.max_length = DataStore.PLAYER_NAME_MAX_LEN
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# 用 LineEdit 的文本宽度占用最小宽（默认行为），但把占位文字压短；
	# 实际名称被截断时由 LineEdit 自身横向滚动，不影响面板宽度。
	_name_edit.custom_minimum_size = Vector2(NAME_EDIT_MIN_W if not _compact else NAME_EDIT_MIN_W_NARROW, 0)
	UiStyle.inline_line_edit(_name_edit, racer_color, 15 if not _compact else 13)
	_name_edit.text_submitted.connect(_on_name_submitted)
	_name_edit.focus_exited.connect(_on_name_focus_exited)
	head.add_child(_name_edit)

	# 累计胜场徽标（无胜场时隐藏）
	_wins_label = Label.new()
	_wins_label.add_theme_font_size_override("font_size", 12 if not _compact else 11)
	_wins_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.40))
	_wins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	# 徽标不可抢宽度：缩到 0 最小宽，过长时省略号
	_wins_label.size_flags_horizontal = Control.SIZE_SHRINK_END
	_wins_label.custom_minimum_size = Vector2.ZERO
	_wins_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_wins_label.visible = false
	head.add_child(_wins_label)

	# 实时分数
	_score_label = Label.new()
	_score_label.text = "0/%d" % max_score
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_score_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_score_label.add_theme_font_size_override("font_size", 26 if not _compact else 20)
	_score_label.add_theme_color_override("font_color", racer_color.lightened(0.35))
	_score_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.add_child(_score_label)

	# +/- 按钮
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8 if not _compact else 6)
	vb.add_child(row)

	_minus_button = _make_button("-", Color(0.85, 0.30, 0.30))
	_minus_button.pressed.connect(_on_minus_pressed)
	row.add_child(_minus_button)

	_plus_button = _make_button("+", Color(0.25, 0.75, 0.42))
	_plus_button.pressed.connect(_on_plus_pressed)
	row.add_child(_plus_button)

	# 点击面板任意空白处 / 其他控件时，让正在编辑的名称框失焦并提交
	UiStyle.focus_on_click_recursive(self)


func _make_button(text_value: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text_value
	b.custom_minimum_size = Vector2(0, 52) if not _compact else Vector2(0, 44)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size", 26 if not _compact else 22)
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
	# 紧凑模式且空间紧时，胜场徽标只显编号（如“胜2”），过长的文案省略
	_wins_label.queue_redraw()


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
