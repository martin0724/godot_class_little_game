extends RefCounted
## 共用 UI 样式与控件辅助（全部为静态方法）。
## 通过 const UiStyle := preload("res://scripts/ui_style.gd") 使用，
## 不注册为全局类，避免依赖编辑器的类名缓存。


## HUD 小按钮：深色圆角 + 描边。
static func hud_button(btn: Button, danger := false, accent_override := Color(0, 0, 0, 0)) -> void:
	btn.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))

	var accent: Color = accent_override
	if accent.a <= 0.0:
		accent = Color(0.95, 0.45, 0.42, 0.80) if danger else Color(0.45, 0.70, 0.95, 0.60)

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.16, 0.28, 0.78)
	normal.set_corner_radius_all(10)
	normal.set_border_width_all(2)
	normal.border_color = accent
	normal.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(0.32, 0.13, 0.15, 0.92) if danger else Color(0.10, 0.24, 0.40, 0.92)
	hover.border_color = accent.lightened(0.25)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed: StyleBoxFlat = normal.duplicate()
	if danger:
		pressed.bg_color = Color(0.48, 0.17, 0.18, 0.95)
	else:
		# 静音按钮的按下态 = “已静音”，用红色提示
		pressed.bg_color = Color(0.55, 0.25, 0.28, 0.95)
		pressed.border_color = Color(1.0, 0.55, 0.50, 0.9)
	btn.add_theme_stylebox_override("pressed", pressed)


## 实心按钮（主操作按钮）。
static func filled_button(btn: Button, base: Color) -> void:
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.4))

	var normal := StyleBoxFlat.new()
	normal.bg_color = base
	normal.set_corner_radius_all(10)
	normal.set_content_margin_all(6)
	btn.add_theme_stylebox_override("normal", normal)

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = base.lightened(0.16)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = base.darkened(0.20)
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(0.30, 0.30, 0.30, 0.60)
	btn.add_theme_stylebox_override("disabled", disabled)


## 递归处理整棵子树：把所有“非交互控件”（focus_mode 仍为 NONE 的容器 / 背景 / 根控件）
## 设为点击即可获取焦点——这样正在编辑的输入框会失焦，触发 focus_exited 把数据存回去。
## 按钮、输入框等已有焦点模式的控件不受影响。
static func focus_on_click_recursive(node: Node) -> void:
	if node is Control:
		var control := node as Control
		if control.focus_mode == Control.FOCUS_NONE:
			control.focus_mode = Control.FOCUS_CLICK
	for child in node.get_children():
		focus_on_click_recursive(child)


## 内联可编辑文本框：平常看起来就像普通文字，聚焦时才显示底色与下划线。
static func inline_line_edit(edit: LineEdit, accent := Color(0.45, 0.75, 1.0), font_size := 15) -> void:
	edit.add_theme_font_size_override("font_size", font_size)
	edit.add_theme_color_override("font_color", Color(0.93, 0.97, 1.0))
	edit.add_theme_color_override("font_placeholder_color", Color(0.70, 0.80, 0.90, 0.50))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(1, 1, 1, 0.0)
	normal.set_corner_radius_all(6)
	normal.content_margin_left = 5
	normal.content_margin_right = 5
	normal.content_margin_top = 2
	normal.content_margin_bottom = 2
	edit.add_theme_stylebox_override("normal", normal)

	var focus: StyleBoxFlat = normal.duplicate()
	focus.bg_color = Color(1, 1, 1, 0.14)
	focus.border_width_bottom = 2
	focus.border_color = accent
	edit.add_theme_stylebox_override("focus", focus)

	var read_only: StyleBoxFlat = normal.duplicate()
	read_only.bg_color = Color(1, 1, 1, 0.04)
	edit.add_theme_stylebox_override("read_only", read_only)


## 卡片式面板样式。
static func card_style(bg := Color(0.05, 0.13, 0.24, 0.96), border := Color(0.35, 0.60, 0.90, 0.50), radius := 18, border_width := 2, margin := 22) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.set_corner_radius_all(radius)
	style.set_border_width_all(border_width)
	style.border_color = border
	style.set_content_margin_all(margin)
	return style


## 生成一个模态确认框并挂到 parent 下，返回该覆盖层（调用方保存引用，关闭时 queue_free 即可）。
static func confirm_dialog(parent: Node, title: String, body: String, cancel_text: String, confirm_text: String, on_confirmed: Callable, danger := true) -> Control:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(overlay)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", card_style(
		Color(0.05, 0.13, 0.24, 0.98),
		Color(0.95, 0.45, 0.42) if danger else Color(0.45, 0.70, 0.95),
		18, 3, 26
	))
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	card.add_child(vb)

	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 24)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.62, 0.58) if danger else Color(0.70, 0.88, 1.0))
	vb.add_child(title_label)

	var body_label := Label.new()
	body_label.text = body
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.add_theme_font_size_override("font_size", 15)
	body_label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.9))
	vb.add_child(body_label)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vb.add_child(row)

	var cancel := Button.new()
	cancel.text = cancel_text
	cancel.custom_minimum_size = Vector2(130, 46)
	cancel.add_theme_font_size_override("font_size", 17)
	cancel.pressed.connect(func() -> void: overlay.queue_free())
	row.add_child(cancel)

	var confirm := Button.new()
	confirm.text = confirm_text
	confirm.custom_minimum_size = Vector2(130, 46)
	confirm.add_theme_font_size_override("font_size", 17)
	filled_button(confirm, Color(0.78, 0.30, 0.30) if danger else Color(0.20, 0.55, 0.85))
	confirm.pressed.connect(func() -> void:
		overlay.queue_free()
		on_confirmed.call()
	)
	row.add_child(confirm)

	return overlay
