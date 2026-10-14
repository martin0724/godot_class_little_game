extends Control
## 潜艇大作战 / Submarine Race —— 主控制器。
## 负责搭建赛道（8 条垂直航道 × 20 格）、潜水艇、底部操作面板，
## 并处理加减分、获胜结算等游戏逻辑。

const RACER_COUNT := 8    ## 潜水艇数量
const MAX_SCORE := 20     ## 到达 20 格（水面）获胜

# —— 设计分辨率坐标系（配合项目 stretch=canvas_items / aspect=keep）——
const VIEW_W := 1280.0
const VIEW_H := 800.0
const SKY_H := 75.0       ## 天空 / 水面高度，同时也是 FINISH 终点线位置
const PANEL_TOP := 620.0  ## 底部操作面板起始 y
const GRID_H := 26.0      ## 每格高度
const GRID_ZERO_Y := 595.0  ## 0 分（水底）时潜水艇中心 y
const SIDE_MARGIN := 20.0

## 彩虹配色
const RACER_COLORS: Array[Color] = [
	Color(0.906, 0.298, 0.235),  # 红
	Color(0.902, 0.494, 0.133),  # 橙
	Color(0.945, 0.769, 0.059),  # 黄
	Color(0.180, 0.800, 0.443),  # 绿
	Color(0.102, 0.737, 0.612),  # 青
	Color(0.204, 0.596, 0.859),  # 蓝
	Color(0.608, 0.349, 0.714),  # 紫
	Color(0.910, 0.263, 0.576),  # 粉
]

const NAME_MAX_LEN := 12

# —— 右上角 HUD 按钮布局 ——
const HUD_Y := 16.0
const HUD_H := 38.0
const HUD_GAP := 8.0
const HUD_SOUND_W := 136.0
const HUD_LANG_W := 100.0
const HUD_RESET_W := 110.0

var _submarines: Array[Submarine] = []
var _panels: Array[ControlPanel] = []
var _names: Array[String] = []   ## 当前玩家名称（可编辑）
var _scores: Array[int] = []     ## 本局起始分数（从存档恢复）
var _game_over := false
var _winner_index := -1
var _title_label: Label
var _finish_label: Label
var _mute_button: Button
var _reset_button: Button
var _lang_button: Button
var _reset_dialog: Control
var _overlay: Control


func _ready() -> void:
	I18n.locale_changed.connect(_on_locale_changed)
	_load_players()
	_build_world()
	_build_dashboard()
	_build_hud()
	queue_redraw()


## 当前语言下的默认玩家名（未自定义名称时显示）。
func _default_name(index: int) -> String:
	return I18n.t("PLAYER_NAME", [index + 1])


## 从 JSON 存档载入玩家名称与分数。
## 若上一局已分出胜负（有人到达水面），自动开新一局（分数清零）。
func _load_players() -> void:
	var use_save := DataStore.get_player_count() == RACER_COUNT
	if use_save:
		for i in RACER_COUNT:
			if DataStore.get_player_score(i) >= MAX_SCORE:
				DataStore.reset_scores()
				break

	_names.clear()
	_scores.clear()
	for i in RACER_COUNT:
		var player_name := _default_name(i)
		var player_score := 0
		if use_save:
			var loaded := DataStore.get_player_name(i)
			if not loaded.is_empty():
				player_name = loaded
			player_score = clampi(DataStore.get_player_score(i), 0, MAX_SCORE)
		_names.append(player_name)
		_scores.append(player_score)


# ——————————————————— 布局计算 ———————————————————

func _lane_width() -> float:
	return (VIEW_W - SIDE_MARGIN * 2.0) / float(RACER_COUNT)


func _lane_center_x(index: int) -> float:
	return SIDE_MARGIN + _lane_width() * (float(index) + 0.5)


## 第 score 格对应的 y 坐标（0 格在水底，20 格在水面）。
func _grid_y(score: int) -> float:
	return GRID_ZERO_Y - float(score) * GRID_H


# ——————————————————— 场景搭建 ———————————————————

func _build_world() -> void:
	for i in RACER_COUNT:
		var sub := Submarine.new()
		sub.setup(i + 1, RACER_COLORS[i], MAX_SCORE)
		sub.pet_kind = i
		sub.home_x = _lane_center_x(i)
		sub.score = _scores[i]
		sub.position = Vector2(sub.home_x, _grid_y(_scores[i]))
		sub.set_target_y(_grid_y(_scores[i]))
		add_child(sub)
		_submarines.append(sub)

	var title := Label.new()
	title.text = I18n.t("GAME_TITLE")
	title.position = Vector2(SIDE_MARGIN, 10)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.08, 0.24, 0.4, 0.9))
	add_child(title)
	_title_label = title

	var finish := Label.new()
	finish.text = I18n.t("FINISH_LINE")
	finish.position = Vector2(VIEW_W * 0.5 - 100.0, SKY_H - 36.0)
	finish.size = Vector2(200, 30)
	finish.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish.add_theme_font_size_override("font_size", 22)
	finish.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	finish.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.5))
	finish.add_theme_constant_override("outline_size", 4)
	add_child(finish)
	_finish_label = finish


func _build_dashboard() -> void:
	var bar := HBoxContainer.new()
	bar.position = Vector2(SIDE_MARGIN, PANEL_TOP + 12.0)
	bar.size = Vector2(VIEW_W - SIDE_MARGIN * 2.0, VIEW_H - PANEL_TOP - 24.0)
	bar.add_theme_constant_override("separation", 8)
	add_child(bar)

	for i in RACER_COUNT:
		var panel := ControlPanel.new()
		panel.setup(i, RACER_COLORS[i], _names[i], MAX_SCORE)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.score_requested.connect(_on_score_requested)
		panel.name_changed.connect(_on_name_changed)
		bar.add_child(panel)
		panel.set_score(_scores[i])
		panel.set_wins(DataStore.get_player_wins(i))
		_panels.append(panel)


## 顶部 HUD：右上角的「语言切换」「重置存档」与「全局静音」开关。
func _build_hud() -> void:
	var right := VIEW_W - SIDE_MARGIN
	var sound_x := right - HUD_SOUND_W
	var lang_x := sound_x - HUD_GAP - HUD_LANG_W
	var reset_x := lang_x - HUD_GAP - HUD_RESET_W

	_reset_button = Button.new()
	_reset_button.focus_mode = Control.FOCUS_NONE
	_reset_button.text = I18n.t("BTN_RESET")
	_reset_button.position = Vector2(reset_x, HUD_Y)
	_reset_button.size = Vector2(HUD_RESET_W, HUD_H)
	_reset_button.add_theme_font_size_override("font_size", 15)
	_style_hud_button(_reset_button, true)
	_reset_button.pressed.connect(_on_reset_pressed)
	add_child(_reset_button)

	_lang_button = Button.new()
	_lang_button.focus_mode = Control.FOCUS_NONE
	_lang_button.text = I18n.switch_button_text()
	_lang_button.position = Vector2(lang_x, HUD_Y)
	_lang_button.size = Vector2(HUD_LANG_W, HUD_H)
	_lang_button.add_theme_font_size_override("font_size", 15)
	_style_hud_button(_lang_button, false, Color(0.55, 0.85, 0.65, 0.70))
	_lang_button.pressed.connect(_on_lang_pressed)
	add_child(_lang_button)

	_mute_button = Button.new()
	_mute_button.toggle_mode = true
	_mute_button.focus_mode = Control.FOCUS_NONE
	_mute_button.position = Vector2(sound_x, HUD_Y)
	_mute_button.size = Vector2(HUD_SOUND_W, HUD_H)
	_mute_button.add_theme_font_size_override("font_size", 16)
	_style_hud_button(_mute_button)
	_mute_button.button_pressed = SoundManager.is_muted()
	_update_mute_text()
	_mute_button.toggled.connect(_on_mute_toggled)
	add_child(_mute_button)


func _style_hud_button(btn: Button, danger: bool = false, accent_override: Color = Color(0, 0, 0, 0)) -> void:
	btn.add_theme_color_override("font_color", Color(0.90, 0.96, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	btn.add_theme_color_override("font_pressed_color", Color(1, 1, 1))

	var accent := accent_override if accent_override.a > 0.0 else (Color(0.95, 0.45, 0.42, 0.80) if danger else Color(0.45, 0.70, 0.95, 0.60))

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


func _update_mute_text() -> void:
	_mute_button.text = I18n.t("BTN_SOUND_OFF" if _mute_button.button_pressed else "BTN_SOUND_ON")


func _on_mute_toggled(pressed: bool) -> void:
	SoundManager.set_muted(pressed)
	_update_mute_text()


# ——————————————————— 语言切换 ———————————————————

func _on_lang_pressed() -> void:
	I18n.toggle()


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


## 语言切换后就地刷新全部文案（不重建场景，不影响正在进行的一局）。
func _refresh_texts() -> void:
	if _title_label:
		_title_label.text = I18n.t("GAME_TITLE")
	if _finish_label:
		_finish_label.text = I18n.t("FINISH_LINE")
	if _reset_button:
		_reset_button.text = I18n.t("BTN_RESET")
	if _lang_button:
		_lang_button.text = I18n.switch_button_text()
	if _mute_button:
		_update_mute_text()

	# 未自定义名称的玩家跟随语言显示默认名
	for i in _panels.size():
		if DataStore.get_player_name(i).is_empty():
			_names[i] = _default_name(i)
			_panels[i].set_name_text(_names[i])
		_panels[i].refresh_texts()

	# 已打开的弹窗按新语言重建
	if _overlay and _winner_index >= 0:
		_overlay.queue_free()
		_overlay = null
		_show_winner(_winner_index)
	if _reset_dialog:
		_close_reset_confirm()
		_show_reset_confirm()


# ——————————————————— 重置存档与配置 ———————————————————

func _on_reset_pressed() -> void:
	_show_reset_confirm()


func _show_reset_confirm() -> void:
	if _reset_dialog:
		return

	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_reset_dialog = overlay

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.13, 0.24, 0.98)
	style.set_corner_radius_all(18)
	style.set_border_width_all(3)
	style.border_color = Color(0.95, 0.45, 0.42)
	style.set_content_margin_all(26)
	card.add_theme_stylebox_override("panel", style)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	card.add_child(vb)

	var title := Label.new()
	title.text = I18n.t("RESET_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.62, 0.58))
	vb.add_child(title)

	var msg := Label.new()
	msg.text = I18n.t("RESET_BODY")
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.add_theme_font_size_override("font_size", 15)
	msg.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 0.9))
	vb.add_child(msg)

	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	vb.add_child(row)

	var cancel := Button.new()
	cancel.text = I18n.t("BTN_CANCEL")
	cancel.custom_minimum_size = Vector2(130, 46)
	cancel.add_theme_font_size_override("font_size", 17)
	cancel.pressed.connect(_close_reset_confirm)
	row.add_child(cancel)

	var confirm := Button.new()
	confirm.text = I18n.t("BTN_CONFIRM_RESET")
	confirm.custom_minimum_size = Vector2(130, 46)
	confirm.add_theme_font_size_override("font_size", 17)
	confirm.pressed.connect(_do_reset)
	row.add_child(confirm)


func _close_reset_confirm() -> void:
	if _reset_dialog:
		_reset_dialog.queue_free()
		_reset_dialog = null


## 完整入口：清空存档并重建场景。
func _do_reset() -> void:
	_close_reset_confirm()
	perform_reset()
	get_tree().reload_current_scene()


## 清空 JSON 存档（含配置）并同步运行时状态（不重建场景）。
func perform_reset() -> void:
	DataStore.reset_all()
	SoundManager.reload_settings()
	I18n.reload_settings()


## 玩家改名：清洗后回写；留空则回退到当前语言的默认名。
func _on_name_changed(index: int, new_name: String) -> void:
	var final_name := new_name.strip_edges()
	if final_name.length() > NAME_MAX_LEN:
		final_name = final_name.substr(0, NAME_MAX_LEN)

	if final_name.is_empty():
		# 存空串 = “未自定义”，显示时按语言给出默认名
		DataStore.set_player_name(index, "")
		_names[index] = _default_name(index)
	else:
		DataStore.set_player_name(index, final_name)
		_names[index] = final_name
	_panels[index].set_name_text(_names[index])


# ——————————————————— 游戏逻辑 ———————————————————

func _on_score_requested(index: int, delta: int) -> void:
	if _game_over:
		return
	var sub := _submarines[index]
	if sub.locked:
		return
	SoundManager.play_click()

	var value := clampi(sub.score + delta, 0, MAX_SCORE)
	if value == sub.score:
		# 已在边界（水底 0 或水面 20），只做反馈
		SoundManager.play_denied()
		sub.flash(Color(1, 1, 1, 0.6))
		return

	sub.score = value
	sub.set_target_y(_grid_y(value))

	if delta > 0:
		SoundManager.play_up()
		sub.flash(Color(1, 1, 1))
		sub.burst(16)
	else:
		SoundManager.play_down()
		sub.flash(Color(1, 0.5, 0.4))
		sub.burst(7)

	_panels[index].set_score(value)
	DataStore.set_player_score(index, value)

	if value >= MAX_SCORE:
		_trigger_win(index)


func _trigger_win(index: int) -> void:
	_game_over = true
	_winner_index = index
	SoundManager.play_win()
	DataStore.record_win(index)
	var sub := _submarines[index]
	sub.locked = true
	sub.celebrating = true
	# 停止所有加减分操作
	for panel in _panels:
		panel.set_buttons_enabled(false)
	# 更新该玩家的胜场徽标
	_panels[index].set_wins(DataStore.get_player_wins(index))
	_show_winner(index)


func _show_winner(index: int) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	_overlay = overlay

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var card := PanelContainer.new()
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.05, 0.14, 0.26, 0.98)
	card_style.set_corner_radius_all(20)
	card_style.set_border_width_all(3)
	card_style.border_color = RACER_COLORS[index]
	card_style.set_content_margin_all(30)
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	card.add_child(vb)

	var winner := Label.new()
	winner.text = I18n.t("WIN_TITLE", [_names[index]])
	winner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner.add_theme_font_size_override("font_size", 34)
	winner.add_theme_color_override("font_color", RACER_COLORS[index].lightened(0.4))
	vb.add_child(winner)

	var subtitle := Label.new()
	subtitle.text = I18n.t("WIN_SUBTITLE", [MAX_SCORE, MAX_SCORE])
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0, 0.85))
	vb.add_child(subtitle)

	# 来自 JSON 存档的累计数据
	var stats := Label.new()
	stats.text = I18n.t("WIN_STATS", [DataStore.get_player_wins(index), DataStore.get_matches_played()])
	stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats.add_theme_font_size_override("font_size", 14)
	stats.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45, 0.9))
	vb.add_child(stats)

	var restart := Button.new()
	restart.text = I18n.t("BTN_PLAY_AGAIN")
	restart.custom_minimum_size = Vector2(200, 50)
	restart.add_theme_font_size_override("font_size", 20)
	restart.pressed.connect(_on_restart_pressed)
	vb.add_child(restart)

	# 淡入
	var tween := create_tween()
	tween.tween_property(overlay, "color:a", 0.55, 0.35)


func _on_restart_pressed() -> void:
	if _overlay:
		_overlay.queue_free()
		_overlay = null
	_reset_game()


## 原地重置（不重载场景，保留玩家名称与静音设置）。
func _reset_game() -> void:
	_game_over = false
	_winner_index = -1
	DataStore.reset_scores()
	for i in _submarines.size():
		var sub := _submarines[i]
		sub.score = 0
		sub.locked = false
		sub.celebrating = false
		sub.set_target_y(_grid_y(0))
		sub.position = Vector2(sub.home_x, _grid_y(0))
		_panels[i].set_score(0)
		_panels[i].set_buttons_enabled(true)


# ——————————————————— 背景绘制 ———————————————————

func _draw() -> void:
	# 天空 / 水面（自上而下由深蓝到浅蓝）
	draw_polygon(
		PackedVector2Array([Vector2(0, 0), Vector2(VIEW_W, 0), Vector2(VIEW_W, SKY_H), Vector2(0, SKY_H)]),
		PackedColorArray([Color(0.36, 0.70, 0.91), Color(0.36, 0.70, 0.91), Color(0.78, 0.93, 1.0), Color(0.78, 0.93, 1.0)])
	)

	# 深海（越往下越暗）
	draw_polygon(
		PackedVector2Array([Vector2(0, SKY_H), Vector2(VIEW_W, SKY_H), Vector2(VIEW_W, PANEL_TOP), Vector2(0, PANEL_TOP)]),
		PackedColorArray([Color(0.11, 0.42, 0.66), Color(0.11, 0.42, 0.66), Color(0.02, 0.13, 0.23), Color(0.02, 0.13, 0.23)])
	)

	# 底部操作区底色
	draw_rect(Rect2(0, PANEL_TOP, VIEW_W, VIEW_H - PANEL_TOP), Color(0.024, 0.078, 0.13))

	# 20 格水平网格线
	for g in range(0, MAX_SCORE + 1):
		var y := _grid_y(g)
		var alpha := 0.22 if g == MAX_SCORE else 0.09
		draw_dashed_line(Vector2(SIDE_MARGIN, y), Vector2(VIEW_W - SIDE_MARGIN, y), Color(1, 1, 1, alpha), 1.0, 7.0)

	# 航道分隔线
	var lw := _lane_width()
	for i in range(RACER_COUNT + 1):
		var x := SIDE_MARGIN + lw * float(i)
		draw_dashed_line(Vector2(x, SKY_H), Vector2(x, GRID_ZERO_Y + GRID_H * 0.7), Color(1, 1, 1, 0.07), 1.0, 12.0)

	# FINISH 终点线（水面）
	draw_dashed_line(Vector2(0, SKY_H), Vector2(VIEW_W, SKY_H), Color(1, 1, 1, 0.95), 3.0, 16.0)
