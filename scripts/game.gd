extends Control
## 潜艇大作战 / Submarine Race —— 主控制器。
## 负责搭建赛道（N 条垂直航道 × M 格）、潜水艇、底部操作面板，
## 并处理加减分、获胜结算等游戏逻辑。
## 玩家数量与终点分数来自当前存档（在存档选择场景中创建）。

const UiStyle := preload("res://scripts/ui_style.gd")
const SeaAnimal := preload("res://scripts/sea_animal.gd")

# —— 设计分辨率坐标系（配合项目 stretch=canvas_items / aspect=keep）——
const VIEW_W := 1280.0
const VIEW_H := 800.0
const SKY_H := 75.0       ## 天空 / 水面高度，同时也是 FINISH 终点线位置
const PANEL_TOP := 620.0  ## 底部操作面板起始 y
const GRID_ZERO_Y := 595.0  ## 0 分（水底）时潜水艇中心 y
const SIDE_MARGIN := 20.0
const PANEL_MIN_W := 118.0  ## 单个玩家面板的最小宽度（超出则横向滚动）

const NAME_MAX_LEN := 12

# —— 右上角 HUD 按钮布局 ——
const HUD_Y := 16.0
const HUD_H := 38.0
const HUD_GAP := 8.0
const HUD_SOUND_W := 136.0
const HUD_LANG_W := 100.0
const HUD_RESET_W := 96.0
const HUD_BACK_W := 96.0
const HUD_SUMMON_W := 96.0

# —— 海洋动物 ——
const AMBIENT_COUNT := 9        ## 常驻装饰动物数量
const MAX_SPECIALS := 3         ## 同时存在的章鱼/鲨鱼上限
const HIT_RADIUS := 52.0        ## 与潜艇的触碰判定半径
const SEA_TOP := 120.0          ## 动物活动的海水区域上边界
const SEA_BOTTOM := 588.0       ## 下边界

var _racer_count := 8   ## 来自当前存档
var _max_score := 20    ## 来自当前存档

var _submarines: Array[Submarine] = []
var _panels: Array[ControlPanel] = []
var _names: Array[String] = []   ## 当前玩家名称（可编辑）
var _scores: Array[int] = []     ## 本局起始分数（从存档恢复）
var _game_over := false
var _winner_index := -1
var _title_label: Label
var _slot_label: Label
var _finish_label: Label
var _mute_button: Button
var _reset_button: Button
var _lang_button: Button
var _back_button: Button
var _summon_button: Button
var _reset_dialog: Control
var _overlay: Control

var _ambient_layer: Node2D
var _critter_layer: Node2D
var _specials: Array = []


func _ready() -> void:
	if not DataStore.has_active_slot():
		_go_to_save_select()
		return
	_racer_count = maxi(1, DataStore.get_active_player_count())
	_max_score = maxi(1, DataStore.get_active_max_score())

	I18n.locale_changed.connect(_on_locale_changed)
	_load_players()
	_build_world()
	_build_dashboard()
	_build_hud()
	set_process(true)
	queue_redraw()


func _go_to_save_select() -> void:
	get_tree().change_scene_to_file("res://scenes/save_select.tscn")


## 当前语言下的默认玩家名（未自定义名称时显示）。
func _default_name(index: int) -> String:
	return I18n.t("PLAYER_NAME", [index + 1])


## 彩虹配色：按玩家数量均匀取色相，支持任意人数。
func _racer_color(index: int) -> Color:
	var count := maxi(1, _racer_count)
	return Color.from_hsv(fmod(float(index) / float(count) + 0.02, 1.0), 0.72, 0.95)


## 从当前存档载入玩家名称与分数。
## 若上一局已分出胜负（有人到达水面），自动开新一局（分数清零）。
func _load_players() -> void:
	var use_save := DataStore.get_player_count() == _racer_count
	if use_save:
		for i in _racer_count:
			if DataStore.get_player_score(i) >= _max_score:
				DataStore.reset_scores()
				break

	_names.clear()
	_scores.clear()
	for i in _racer_count:
		var player_name := _default_name(i)
		var player_score := 0
		if use_save:
			var loaded := DataStore.get_player_name(i)
			if not loaded.is_empty():
				player_name = loaded
			player_score = clampi(DataStore.get_player_score(i), 0, _max_score)
		_names.append(player_name)
		_scores.append(player_score)


# ——————————————————— 布局计算 ———————————————————

func _lane_width() -> float:
	return (VIEW_W - SIDE_MARGIN * 2.0) / float(maxi(1, _racer_count))


func _lane_center_x(index: int) -> float:
	return SIDE_MARGIN + _lane_width() * (float(index) + 0.5)


## 每格高度：把水面到水底的高度均分给 _max_score 格。
func _grid_h() -> float:
	return (GRID_ZERO_Y - SKY_H) / float(maxi(1, _max_score))


## 第 score 格对应的 y 坐标（0 格在水底，_max_score 格在水面）。
func _grid_y(score: int) -> float:
	return GRID_ZERO_Y - float(score) * _grid_h()


# ——————————————————— 场景搭建 ———————————————————

func _build_world() -> void:
	# 装饰动物层：在潜艇之后方
	_ambient_layer = Node2D.new()
	_ambient_layer.name = "AmbientAnimals"
	add_child(_ambient_layer)

	for i in _racer_count:
		var sub := Submarine.new()
		sub.setup(i + 1, _racer_color(i), _max_score)
		sub.pet_kind = i
		sub.home_x = _lane_center_x(i)
		sub.score = _scores[i]
		sub.position = Vector2(sub.home_x, _grid_y(_scores[i]))
		sub.set_target_y(_grid_y(_scores[i]))
		add_child(sub)
		_submarines.append(sub)

	# 章鱼 / 鲨鱼层：在潜艇之前方，便于表现抓取 / 撕咬
	_critter_layer = Node2D.new()
	_critter_layer.name = "SpecialAnimals"
	add_child(_critter_layer)

	_spawn_ambient_animals()

	var title := Label.new()
	title.text = I18n.t("GAME_TITLE")
	title.position = Vector2(SIDE_MARGIN, 10)
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.08, 0.24, 0.4, 0.9))
	add_child(title)
	_title_label = title

	_slot_label = Label.new()
	_slot_label.text = DataStore.get_active_slot_name()
	_slot_label.position = Vector2(SIDE_MARGIN + 250.0, 12.0)
	_slot_label.size = Vector2(250.0, 24.0)
	_slot_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_slot_label.add_theme_font_size_override("font_size", 15)
	_slot_label.add_theme_color_override("font_color", Color(0.10, 0.28, 0.45, 0.75))
	add_child(_slot_label)

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


## 底部操作面板：人数较多时自动出现横向滚动条。
func _build_dashboard() -> void:
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(SIDE_MARGIN, PANEL_TOP + 12.0)
	scroll.size = Vector2(VIEW_W - SIDE_MARGIN * 2.0, VIEW_H - PANEL_TOP - 24.0)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var bar := HBoxContainer.new()
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bar.add_theme_constant_override("separation", 8)
	scroll.add_child(bar)

	for i in _racer_count:
		var panel := ControlPanel.new()
		panel.setup(i, _racer_color(i), _names[i], _max_score)
		panel.custom_minimum_size = Vector2(PANEL_MIN_W, 0)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		panel.score_requested.connect(_on_score_requested)
		panel.name_changed.connect(_on_name_changed)
		bar.add_child(panel)
		panel.set_score(_scores[i])
		panel.set_wins(DataStore.get_player_wins(i))
		_panels.append(panel)


## 顶部 HUD：右上角的「召唤」「存档」「重置」「语言」「音效」按钮。
func _build_hud() -> void:
	var sound_x := VIEW_W - SIDE_MARGIN - HUD_SOUND_W
	var lang_x := sound_x - HUD_GAP - HUD_LANG_W
	var reset_x := lang_x - HUD_GAP - HUD_RESET_W
	var back_x := reset_x - HUD_GAP - HUD_BACK_W
	var summon_x := back_x - HUD_GAP - HUD_SUMMON_W

	_summon_button = _make_hud_button(I18n.t("BTN_SUMMON"), Vector2(summon_x, HUD_Y), HUD_SUMMON_W, false, Color(0.72, 0.52, 0.96, 0.75))
	_summon_button.pressed.connect(_on_summon_pressed)
	add_child(_summon_button)

	_back_button = _make_hud_button(I18n.t("BTN_BACK_TO_SAVES"), Vector2(back_x, HUD_Y), HUD_BACK_W)
	_back_button.pressed.connect(_on_back_pressed)
	add_child(_back_button)

	_reset_button = _make_hud_button(I18n.t("BTN_RESET_SLOT"), Vector2(reset_x, HUD_Y), HUD_RESET_W, true)
	_reset_button.pressed.connect(_on_reset_pressed)
	add_child(_reset_button)

	_lang_button = _make_hud_button(I18n.switch_button_text(), Vector2(lang_x, HUD_Y), HUD_LANG_W, false, Color(0.55, 0.85, 0.65, 0.70))
	_lang_button.pressed.connect(_on_lang_pressed)
	add_child(_lang_button)

	_mute_button = _make_hud_button("", Vector2(sound_x, HUD_Y), HUD_SOUND_W)
	_mute_button.toggle_mode = true
	_mute_button.add_theme_font_size_override("font_size", 16)
	_mute_button.button_pressed = SoundManager.is_muted()
	_update_mute_text()
	_mute_button.toggled.connect(_on_mute_toggled)
	add_child(_mute_button)


func _make_hud_button(text_value: String, pos: Vector2, width: float, danger := false, accent := Color(0, 0, 0, 0)) -> Button:
	var btn := Button.new()
	btn.text = text_value
	btn.focus_mode = Control.FOCUS_NONE
	btn.position = pos
	btn.size = Vector2(width, HUD_H)
	btn.add_theme_font_size_override("font_size", 15)
	UiStyle.hud_button(btn, danger, accent)
	return btn


func _update_mute_text() -> void:
	_mute_button.text = I18n.t("BTN_SOUND_OFF" if _mute_button.button_pressed else "BTN_SOUND_ON")


func _on_mute_toggled(pressed: bool) -> void:
	SoundManager.set_muted(pressed)
	_update_mute_text()


# ——————————————————— 语言切换 / 返回存档 ———————————————————

func _on_lang_pressed() -> void:
	I18n.toggle()


func _on_back_pressed() -> void:
	_go_to_save_select()


func _on_locale_changed(_locale: String) -> void:
	_refresh_texts()


## 语言切换后就地刷新全部文案（不重建场景，不影响正在进行的一局）。
func _refresh_texts() -> void:
	if _title_label:
		_title_label.text = I18n.t("GAME_TITLE")
	if _slot_label:
		_slot_label.text = DataStore.get_active_slot_name()
	if _finish_label:
		_finish_label.text = I18n.t("FINISH_LINE")
	if _back_button:
		_back_button.text = I18n.t("BTN_BACK_TO_SAVES")
	if _summon_button:
		_summon_button.text = I18n.t("BTN_SUMMON")
	if _reset_button:
		_reset_button.text = I18n.t("BTN_RESET_SLOT")
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


# ——————————————————— 重置当前存档 ———————————————————

func _on_reset_pressed() -> void:
	_show_reset_confirm()


func _show_reset_confirm() -> void:
	if _reset_dialog:
		return
	_reset_dialog = UiStyle.confirm_dialog(
		self,
		I18n.t("RESET_SLOT_TITLE"),
		I18n.t("RESET_SLOT_BODY"),
		I18n.t("BTN_CANCEL"),
		I18n.t("BTN_CONFIRM_RESET"),
		_do_reset
	)


func _close_reset_confirm() -> void:
	if _reset_dialog and is_instance_valid(_reset_dialog):
		_reset_dialog.queue_free()
	_reset_dialog = null


## 完整入口：清空当前存档并重建场景。
func _do_reset() -> void:
	_reset_dialog = null
	perform_reset()
	get_tree().reload_current_scene()


## 清空当前存档的名称 / 分数 / 胜场（不重建场景）。
func perform_reset() -> void:
	DataStore.reset_active_slot()


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


# ——————————————————— 海洋动物 ———————————————————

func _sea_bounds() -> Rect2:
	return Rect2(Vector2(56.0, SEA_TOP), Vector2(VIEW_W - 112.0, SEA_BOTTOM - SEA_TOP))


## 常驻装饰动物（小鱼 / 海星）：只在海里随机游动，不触发任何效果。
func _spawn_ambient_animals() -> void:
	var bounds := _sea_bounds()
	for i in AMBIENT_COUNT:
		var animal: Node2D = SeaAnimal.new()
		var kind: int = SeaAnimal.Kind.STARFISH if i % 4 == 3 else SeaAnimal.Kind.FISH
		var speed := randf_range(40.0, 85.0) * (1.0 if randf() < 0.5 else -1.0)
		animal.setup_ambient(kind, i, Vector2(speed, randf_range(-14.0, 14.0)), bounds)
		animal.position = Vector2(
			randf_range(bounds.position.x + 20.0, bounds.position.x + bounds.size.x - 20.0),
			randf_range(bounds.position.y + 20.0, bounds.position.y + bounds.size.y - 20.0)
		)
		_ambient_layer.add_child(animal)


func _on_summon_pressed() -> void:
	if _summon_special():
		SoundManager.play_click()
	else:
		SoundManager.play_denied()


## 生成一只章鱼或鲨鱼（仅由「召唤」按钮触发）。
## forced_kind 传入无效值时按 50% / 50% 随机；生成失败（已达上限）返回 false。
func _summon_special(forced_kind: int = -1) -> bool:
	if _game_over or _submarines.is_empty():
		return false
	# 清理已经淡出销毁的
	_specials = _specials.filter(func(a: Variant) -> bool: return is_instance_valid(a))
	if _specials.size() >= MAX_SPECIALS:
		return false

	var kind := forced_kind
	if kind != SeaAnimal.Kind.OCTOPUS and kind != SeaAnimal.Kind.SHARK:
		kind = SeaAnimal.Kind.OCTOPUS if randi() % 2 == 0 else SeaAnimal.Kind.SHARK

	var bounds := _sea_bounds()
	var from_left := randf() < 0.5
	var spawn_y := randf_range(bounds.position.y + 40.0, bounds.position.y + bounds.size.y - 40.0)
	var target_y: float = _submarines[randi() % _submarines.size()].position.y

	var animal: Node2D = SeaAnimal.new()
	animal.setup_special(kind, randi(), target_y, bounds)
	animal.position = Vector2(
		bounds.position.x - 70.0 if from_left else bounds.position.x + bounds.size.x + 70.0,
		spawn_y
	)
	animal.velocity = Vector2(150.0 if from_left else -150.0, 0.0)
	_critter_layer.add_child(animal)
	animal.grab_effect.connect(_on_grab_effect.bind(animal))
	_specials.append(animal)
	return true


func _process(_delta: float) -> void:
	if _game_over:
		return
	_update_special_targets()
	_check_animal_collisions()


## 让游泳中的章鱼 / 鲨鱼持续朝「水平方向最近的潜艇」高度靠拢，
## 保证它们最终能碰到潜艇（也避免潜艇升降后目标高度过时）。
func _update_special_targets() -> void:
	for animal in _specials:
		if not is_instance_valid(animal) or not animal.is_swimming():
			continue
		# animal 来自无类型数组（Variant），显式声明类型避免无法推导
		var animal_x: float = animal.position.x
		var best_dist: float = INF
		var best_y: float = animal.position.y
		for sub in _submarines:
			var dist: float = absf(sub.position.x - animal_x)
			if dist < best_dist:
				best_dist = dist
				best_y = sub.position.y
		animal.set_target_y(best_y)


func _check_animal_collisions() -> void:
	for animal in _specials:
		if not is_instance_valid(animal) or not animal.is_swimming():
			continue
		for i in _submarines.size():
			var sub := _submarines[i]
			if sub.locked:
				continue
			if animal.position.distance_to(sub.position) <= HIT_RADIUS:
				_start_grab(animal, i)
				break


## 章鱼 / 鲨鱼碰到潜艇：进入抓取 / 撕咬状态，延迟后施加分数变化。
func _start_grab(animal: Node2D, index: int) -> void:
	var sub := _submarines[index]
	var is_octopus: bool = animal.kind == SeaAnimal.Kind.OCTOPUS
	animal.set_meta("target_index", index)
	animal.start_grab(sub, Vector2(-6.0, 24.0) if is_octopus else Vector2(-30.0, 4.0), 0.12 if is_octopus else 0.32)
	if is_octopus:
		SoundManager.play_grab()
	else:
		SoundManager.play_bite()
		sub.flash(Color(1, 0.45, 0.40))


func _on_grab_effect(animal: Node) -> void:
	if not is_instance_valid(animal):
		return
	var index: int = int(animal.get_meta("target_index", -1))
	if index < 0 or index >= _submarines.size():
		return
	var delta: int = 1 if animal.kind == SeaAnimal.Kind.OCTOPUS else -1
	_change_score(index, delta)


# ——————————————————— 游戏逻辑 ———————————————————

func _on_score_requested(index: int, delta: int) -> void:
	if _game_over:
		return
	if _submarines[index].locked:
		return
	SoundManager.play_click()
	_change_score(index, delta)


## 统一的分数变化：更新位置 / 面板 / 存档，返回是否真的发生变化。
func _change_score(index: int, delta: int) -> bool:
	var sub := _submarines[index]
	if sub.locked:
		return false

	var value := clampi(sub.score + delta, 0, _max_score)
	if value == sub.score:
		# 已在边界（水底 0 或水面 _max_score），只做反馈
		SoundManager.play_denied()
		sub.flash(Color(1, 1, 1, 0.6))
		return false

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

	if value >= _max_score:
		_trigger_win(index)
	return true


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
	card.add_theme_stylebox_override("panel", UiStyle.card_style(
		Color(0.05, 0.14, 0.26, 0.98), _racer_color(index), 20, 3, 30
	))
	center.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	card.add_child(vb)

	var winner := Label.new()
	winner.text = I18n.t("WIN_TITLE", [_names[index]])
	winner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	winner.add_theme_font_size_override("font_size", 34)
	winner.add_theme_color_override("font_color", _racer_color(index).lightened(0.4))
	vb.add_child(winner)

	var subtitle := Label.new()
	subtitle.text = I18n.t("WIN_SUBTITLE", [_max_score, _max_score])
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
	if _overlay and is_instance_valid(_overlay):
		_overlay.queue_free()
	_overlay = null
	_reset_game()


## 原地重置（不重载场景，保留玩家名称与胜场）。
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

	# 网格线（0 .. _max_score）
	for g in range(0, _max_score + 1):
		var y := _grid_y(g)
		var alpha := 0.22 if g == _max_score else 0.09
		draw_dashed_line(Vector2(SIDE_MARGIN, y), Vector2(VIEW_W - SIDE_MARGIN, y), Color(1, 1, 1, alpha), 1.0, 7.0)

	# 航道分隔线
	var lane_w := _lane_width()
	for i in range(_racer_count + 1):
		var x := SIDE_MARGIN + lane_w * float(i)
		draw_dashed_line(Vector2(x, SKY_H), Vector2(x, GRID_ZERO_Y + _grid_h() * 0.7), Color(1, 1, 1, 0.07), 1.0, 12.0)

	# FINISH 终点线（水面）
	draw_dashed_line(Vector2(0, SKY_H), Vector2(VIEW_W, SKY_H), Color(1, 1, 1, 0.95), 3.0, 16.0)
