extends Control
## 获胜大奖杯（纯矢量绘制，带脉动光晕与闪光）。
## 通过 const Trophy := preload("res://scripts/trophy.gd") 使用。

const DESIGN_SIZE := 200.0

var _time := 0.0
var _accent := Color(0.98, 0.80, 0.25)


## accent 一般传入获胜者的主色，用作杯面徽章。
func setup(p_accent: Color) -> void:
	_accent = p_accent


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(DESIGN_SIZE, DESIGN_SIZE)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var factor: float = minf(size.x, size.y) / DESIGN_SIZE
	draw_set_transform(size * 0.5, 0.0, Vector2(factor, factor))
	_draw_trophy()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_trophy() -> void:
	var pulse: float = 1.0 + sin(_time * 4.0) * 0.03
	var gold_hi := Color(1.00, 0.94, 0.58)
	var gold := Color(0.96, 0.78, 0.22)
	var gold_mid := Color(0.86, 0.66, 0.14)
	var gold_dark := Color(0.66, 0.46, 0.08)

	# 光晕
	draw_circle(Vector2.ZERO, 76.0 * pulse, Color(1.0, 0.86, 0.40, 0.10))
	draw_circle(Vector2.ZERO, 60.0 * pulse, Color(1.0, 0.90, 0.48, 0.12))

	# 两侧把手
	for side in [-1.0, 1.0]:
		var handle := Vector2(side * 40.0, -24.0)
		draw_arc(handle, 17.0, 0.0, TAU, 28, gold_dark, 7.0)
		draw_arc(handle, 17.0, 0.0, TAU, 28, gold_mid, 3.5)

	# 杯身
	var bowl := PackedVector2Array()
	bowl.append(Vector2(-38.0, -46.0))
	bowl.append(Vector2(38.0, -46.0))
	for i in 16:
		var t := float(i) / 15.0
		bowl.append(Vector2(cos(PI * t) * 38.0, -46.0 + sin(PI * t) * 52.0))
	draw_colored_polygon(bowl, gold)

	# 杯身暗部 / 高光
	draw_colored_polygon(_ellipse(Vector2(15.0, -12.0), 15.0, 33.0, 22), Color(0.0, 0.0, 0.0, 0.10))
	draw_colored_polygon(_ellipse(Vector2(-15.0, -14.0), 9.0, 26.0, 20), Color(1.0, 1.0, 1.0, 0.28))

	# 杯口
	draw_colored_polygon(_ellipse(Vector2(0.0, -46.0), 38.0, 9.0, 28), gold_hi)
	draw_colored_polygon(_ellipse(Vector2(0.0, -45.0), 30.0, 6.5, 24), gold_dark.darkened(0.18))

	# 杯面徽章（获胜者主色）
	draw_circle(Vector2(0.0, -18.0), 13.0, _accent)
	draw_arc(Vector2(0.0, -18.0), 13.0, 0.0, TAU, 24, gold_hi, 3.0)

	# 杯柄
	draw_colored_polygon(PackedVector2Array([
		Vector2(-9.0, 6.0), Vector2(9.0, 6.0), Vector2(6.0, 26.0), Vector2(-6.0, 26.0)
	]), gold_mid)

	# 底座
	draw_colored_polygon(PackedVector2Array([
		Vector2(-22.0, 26.0), Vector2(22.0, 26.0), Vector2(28.0, 38.0), Vector2(-28.0, 38.0)
	]), gold)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-30.0, 38.0), Vector2(30.0, 38.0), Vector2(30.0, 48.0), Vector2(-30.0, 48.0)
	]), gold_dark)

	# 环绕闪光
	for i in 4:
		var angle := _time * 1.3 + float(i) * TAU * 0.25
		var radius := 60.0 + sin(_time * 2.0 + float(i) * 1.4) * 8.0
		var pos := Vector2(cos(angle) * radius, sin(angle) * radius * 0.75)
		var alpha := 0.30 + 0.35 * (0.5 + 0.5 * sin(_time * 3.4 + float(i) * 1.7))
		_draw_sparkle(pos, 7.0, Color(1.0, 1.0, 0.88, alpha))


func _draw_sparkle(center: Vector2, radius: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0.0, -radius), center + Vector2(radius * 0.26, 0.0),
		center + Vector2(0.0, radius), center + Vector2(-radius * 0.26, 0.0),
	]), color)
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(-radius, 0.0), center + Vector2(0.0, radius * 0.26),
		center + Vector2(radius, 0.0), center + Vector2(0.0, -radius * 0.26),
	]), color)


func _ellipse(center: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
