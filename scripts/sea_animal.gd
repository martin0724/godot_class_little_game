extends Node2D
## 海洋动物。
## FISH / STARFISH 为纯装饰，只在海里游动；
## OCTOPUS / SHARK 会与潜水艇互动（碰到后 +1 / -1 分），并播放抓取 / 撕咬动画。
##
## 通过 const SeaAnimal := preload("res://scripts/sea_animal.gd") 使用。

signal grab_effect   ## 抓取 / 撕咬动作到位，可以施加分数影响了

enum Kind { FISH, STARFISH, OCTOPUS, SHARK }
enum Phase { SWIM, GRAB, FADE }

const GRAB_HOLD := 0.65     ## 动作生效后继续跟随的时长
const FADE_TIME := 0.32     ## 淡出时长

var kind: int = Kind.FISH
var facing: float = 1.0     ## 1 = 朝右，-1 = 朝左
var velocity := Vector2.ZERO
var swim_bounds := Rect2(Vector2(50, 120), Vector2(1180, 468))
var max_life := 15.0        ## 特殊动物的存活上限

var _phase: int = Phase.SWIM
var _time := 0.0
var _life := 0.0
var _variant := 0
var _bob := 0.0
var _spin := 0.0
var _target_y := 0.0
var _has_target := false
var _action := 0.0          ## 0..1：鲨鱼张嘴 / 章鱼抱紧
var _fade := 1.0
var _host: Node2D
var _grab_offset := Vector2.ZERO
var _grab_time := 0.0
var _effect_delay := 0.3
var _effect_fired := false


# ——————————————————— 初始化 ———————————————————

## 装饰动物：在给定位置随机游动。
func setup_ambient(p_kind: int, p_variant: int, p_velocity: Vector2, p_bounds: Rect2) -> void:
	kind = p_kind
	_variant = p_variant
	velocity = p_velocity
	swim_bounds = p_bounds
	_has_target = false
	_phase = Phase.SWIM
	facing = 1.0 if velocity.x >= 0.0 else -1.0
	if kind == Kind.STARFISH:
		velocity *= 0.45


## 特殊动物：从屏幕外游入，缓慢逼近 target_y（某艘潜艇的高度）。
func setup_special(p_kind: int, p_variant: int, p_target_y: float, p_bounds: Rect2) -> void:
	kind = p_kind
	_variant = p_variant
	swim_bounds = p_bounds
	_target_y = p_target_y
	_has_target = true
	_phase = Phase.SWIM
	max_life = randf_range(12.0, 18.0)


func is_special() -> bool:
	return kind == Kind.OCTOPUS or kind == Kind.SHARK


## 更新追踪的潜艇高度（由主场景持续喂入，保证最终能碰到潜艇）。
func set_target_y(y: float) -> void:
	_target_y = y
	_has_target = true


func is_swimming() -> bool:
	return _phase == Phase.SWIM


## 被潜水艇“抓住 / 咬住”：跟随 host 移动，delay 秒后发出 grab_effect。
func start_grab(host: Node2D, offset: Vector2, effect_delay: float) -> void:
	_phase = Phase.GRAB
	_host = host
	_grab_offset = offset
	_effect_delay = effect_delay
	_grab_time = 0.0
	_effect_fired = false
	_action = 0.0
	velocity = Vector2.ZERO
	facing = 1.0
	if host:
		position = host.position + offset


# ——————————————————— 每帧 ———————————————————

func _ready() -> void:
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	match _phase:
		Phase.SWIM:
			_process_swim(delta)
		Phase.GRAB:
			_process_grab(delta)
		Phase.FADE:
			_process_fade(delta)

	scale = Vector2(facing, 1.0)
	modulate.a = clampf(_fade, 0.0, 1.0)
	queue_redraw()


func _process_swim(delta: float) -> void:
	_life += delta
	_bob += delta * 2.6

	if kind == Kind.STARFISH:
		_spin += delta * 0.9
		position += velocity * delta
		position.y += sin(_bob) * 8.0 * delta
	else:
		if _has_target:
			var dy := _target_y - position.y
			velocity.y = clampf(velocity.y + signf(dy) * 46.0 * delta, -80.0, 80.0)
			if absf(dy) < 14.0:
				velocity.y *= 0.90
		position += velocity * delta
		position.y += sin(_bob) * 5.0 * delta

	_bounce_in_bounds()

	if absf(velocity.x) > 1.0:
		facing = signf(velocity.x)

	if is_special() and _life >= max_life:
		_phase = Phase.FADE


func _process_grab(delta: float) -> void:
	_grab_time += delta
	if _host and is_instance_valid(_host):
		position = _host.position + _grab_offset
	_action = minf(1.0, _action + delta * (4.0 if kind == Kind.SHARK else 6.0))
	if not _effect_fired and _grab_time >= _effect_delay:
		_effect_fired = true
		grab_effect.emit()
	if _grab_time >= _effect_delay + GRAB_HOLD:
		_phase = Phase.FADE


func _process_fade(delta: float) -> void:
	_fade -= delta / FADE_TIME
	if _fade <= 0.0:
		queue_free()


## 碰到边界就掉头（不直接吸附位置，这样从屏幕外游入的动物能自然滑进来）。
func _bounce_in_bounds() -> void:
	var left := swim_bounds.position.x
	var right := swim_bounds.position.x + swim_bounds.size.x
	var top := swim_bounds.position.y
	var bottom := swim_bounds.position.y + swim_bounds.size.y

	if position.x < left and velocity.x < 0.0:
		velocity.x = -velocity.x
	elif position.x > right and velocity.x > 0.0:
		velocity.x = -velocity.x

	if position.y < top and velocity.y < 0.0:
		velocity.y = -velocity.y
	elif position.y > bottom and velocity.y > 0.0:
		velocity.y = -velocity.y


# ——————————————————— 绘制 ———————————————————

func _draw() -> void:
	match kind:
		Kind.FISH:
			_draw_fish()
		Kind.STARFISH:
			_draw_starfish()
		Kind.OCTOPUS:
			_draw_octopus()
		Kind.SHARK:
			_draw_shark()


func _draw_fish() -> void:
	var palette := [
		Color(1.00, 0.58, 0.18),
		Color(0.20, 0.75, 0.88),
		Color(0.98, 0.80, 0.25),
		Color(1.00, 0.45, 0.62),
	]
	var body: Color = palette[_variant % palette.size()]
	var dark := Color(0.08, 0.10, 0.14)

	# 尾鳍
	draw_colored_polygon(PackedVector2Array([
		Vector2(-11, 0), Vector2(-21, -8), Vector2(-21, 8)
	]), body.darkened(0.20))
	# 背鳍
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -6), Vector2(2, -11), Vector2(6, -5)
	]), body.darkened(0.15))
	# 身体
	draw_colored_polygon(_ellipse(Vector2.ZERO, 12.0, 7.5, 20), body)
	# 高光
	draw_colored_polygon(_ellipse(Vector2(-1, -2.5), 7.0, 2.6, 14), body.lightened(0.35))
	# 眼睛
	draw_circle(Vector2(6.0, -1.5), 2.6, Color(1, 1, 1))
	draw_circle(Vector2(6.6, -1.5), 1.3, dark)


func _draw_starfish() -> void:
	var palette := [
		Color(1.00, 0.55, 0.65),
		Color(1.00, 0.72, 0.35),
	]
	var body: Color = palette[_variant % palette.size()]
	var dark := Color(0.14, 0.10, 0.14)

	var points := PackedVector2Array()
	for i in 10:
		var r := 15.0 if i % 2 == 0 else 6.4
		var a := -PI * 0.5 + PI * float(i) / 5.0 + _spin
		points.append(Vector2(cos(a) * r, sin(a) * r))
	var prev := points[points.size() - 1]
	for p in points:
		draw_colored_polygon(PackedVector2Array([Vector2.ZERO, prev, p]), body)
		prev = p

	# 简单表情
	draw_circle(Vector2(-3.4, -2.0), 1.9, dark)
	draw_circle(Vector2(3.4, -2.0), 1.9, dark)
	draw_circle(Vector2(0.0, 3.6), 1.5, Color(1, 1, 1, 0.9))


func _draw_octopus() -> void:
	var body := Color(0.72, 0.42, 0.85)
	var dark := Color(0.06, 0.05, 0.09)

	# 触手（抱紧时向上张开，像抓住潜艇）
	var spread := 1.0 + _action * 0.55
	var reach := 12.0 + _action * 10.0
	for k in 6:
		var x := -13.0 + float(k) * 5.2
		var sway := sin(_time * 4.5 + float(k) * 1.1) * (2.0 + _action * 2.5)
		var tip := Vector2(x * spread + sway, reach)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x - 2.2, 4.0), Vector2(x + 2.2, 4.0), tip
		]), body.darkened(0.15))

	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 0), 15.0, 14.0, 26), body)
	draw_colored_polygon(_ellipse(Vector2(-4.0, -4.5), 7.0, 4.5, 16), body.lightened(0.28))

	# 眼睛
	draw_circle(Vector2(-5.2, -1.5), 4.0, Color(1, 1, 1))
	draw_circle(Vector2(5.2, -1.5), 4.0, Color(1, 1, 1))
	draw_circle(Vector2(-5.2, -1.0), 2.0, dark)
	draw_circle(Vector2(5.2, -1.0), 2.0, dark)

	# 腮红
	draw_circle(Vector2(-10.5, 4.0), 2.4, Color(1, 0.60, 0.75, 0.7))
	draw_circle(Vector2(10.5, 4.0), 2.4, Color(1, 0.60, 0.75, 0.7))


func _draw_shark() -> void:
	var body := Color(0.46, 0.53, 0.61)
	var belly := Color(0.90, 0.93, 0.96)
	var dark := Color(0.10, 0.12, 0.16)

	# 尾鳍
	draw_colored_polygon(PackedVector2Array([
		Vector2(-40, 0), Vector2(-56, -16), Vector2(-58, -2), Vector2(-56, 16)
	]), body.darkened(0.22))
	# 背鳍
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6, -14), Vector2(4, -30), Vector2(14, -12)
	]), body.darkened(0.12))
	# 胸鳍
	draw_colored_polygon(PackedVector2Array([
		Vector2(2, 8), Vector2(-8, 24), Vector2(14, 12)
	]), body.darkened(0.16))

	# 身体
	draw_colored_polygon(_ellipse(Vector2(0, 0), 46.0, 18.0, 30), body)
	# 肚皮
	draw_colored_polygon(_ellipse(Vector2(2, 8), 34.0, 8.0, 20), belly)
	# 高光
	draw_colored_polygon(_ellipse(Vector2(-6, -7), 22.0, 4.0, 16), body.lightened(0.25))

	# 嘴：_action 越大张得越开
	var gap := 1.5 + _action * 13.0
	var mouth := PackedVector2Array([
		Vector2(14.0, 3.0),
		Vector2(45.0, 0.5 - gap * 0.35),
		Vector2(45.0, 1.5 + gap * 0.65),
		Vector2(14.0, 6.0 + gap * 0.25),
	])
	draw_colored_polygon(mouth, Color(0.32, 0.09, 0.12))

	# 牙齿
	var teeth := Color(1, 1, 1)
	for i in 4:
		var tx := 20.0 + float(i) * 6.4
		var top_y := 1.5 - gap * 0.32 + float(i) * 0.35
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx, top_y), Vector2(tx + 3.4, top_y + 0.4), Vector2(tx + 1.7, top_y + 3.6)
		]), teeth)
		var bot_y := 4.0 + gap * 0.28 - float(i) * 0.30
		draw_colored_polygon(PackedVector2Array([
			Vector2(tx, bot_y), Vector2(tx + 3.4, bot_y - 0.4), Vector2(tx + 1.7, bot_y - 3.6)
		]), teeth)

	# 眼睛
	draw_circle(Vector2(24.0, -8.0), 3.4, Color(1, 1, 1))
	draw_circle(Vector2(25.0, -8.0), 1.8, dark)
	# 鳃
	draw_line(Vector2(10, -8), Vector2(10, 6), body.darkened(0.30), 1.6)


func _ellipse(center: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
