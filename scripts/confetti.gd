extends Node2D
## 撒花（彩纸屑）效果：从画面上方持续飘落并旋转。
## 通过 const Confetti := preload("res://scripts/confetti.gd") 使用。

const VIEW_SIZE := Vector2(1280.0, 800.0)
const GRAVITY := 300.0

const COLORS: Array[Color] = [
	Color(1.00, 0.42, 0.42),
	Color(1.00, 0.72, 0.26),
	Color(1.00, 0.92, 0.35),
	Color(0.42, 0.86, 0.48),
	Color(0.32, 0.76, 0.95),
	Color(0.62, 0.50, 0.95),
	Color(0.98, 0.52, 0.78),
	Color(1.00, 1.00, 1.00),
]

var _pieces: Array = []
var _emit_left := 0.0
var _emit_accum := 0.0
var _rate := 30.0


func _ready() -> void:
	set_process(false)


## 开始撒花：duration 秒内持续飘落，开场先来一波爆发。
func start(duration := 6.0, rate := 30.0) -> void:
	_emit_left = duration
	_rate = rate
	_emit_accum = 0.0
	for i in 70:
		_spawn(true)
	set_process(true)
	queue_redraw()


func _spawn(from_high: bool) -> void:
	var top: float = randf_range(-220.0, -40.0) if from_high else randf_range(-70.0, -10.0)
	_pieces.append({
		"pos": Vector2(randf_range(-40.0, VIEW_SIZE.x + 40.0), top),
		"vel": Vector2(randf_range(-45.0, 45.0), randf_range(60.0, 170.0)),
		"rot": randf() * TAU,
		"spin": randf_range(-5.5, 5.5),
		"w": randf_range(6.0, 12.0),
		"h": randf_range(9.0, 17.0),
		"color": COLORS[randi() % COLORS.size()],
		"life": 0.0,
		"max_life": randf_range(4.5, 7.5),
	})


func _process(delta: float) -> void:
	if _emit_left > 0.0:
		_emit_left -= delta
		_emit_accum += delta * _rate
		while _emit_accum >= 1.0:
			_emit_accum -= 1.0
			_spawn(false)

	var alive: Array = []
	for piece in _pieces:
		var life: float = float(piece["life"]) + delta
		var max_life: float = float(piece["max_life"])
		var pos: Vector2 = piece["pos"]
		if life < max_life and pos.y < VIEW_SIZE.y + 80.0:
			var vel: Vector2 = piece["vel"]
			vel.y += GRAVITY * delta
			vel.x += sin(life * 3.0 + float(piece["rot"])) * 26.0 * delta
			pos += vel * delta
			piece["pos"] = pos
			piece["vel"] = vel
			piece["rot"] = float(piece["rot"]) + float(piece["spin"]) * delta
			piece["life"] = life
			alive.append(piece)
	_pieces = alive

	if _pieces.is_empty() and _emit_left <= 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	for piece in _pieces:
		var life: float = float(piece["life"])
		var max_life: float = float(piece["max_life"])
		var fade := 1.0
		var t: float = life / max_life
		if t > 0.72:
			fade = (1.0 - t) / 0.28

		var color: Color = piece["color"]
		color.a *= clampf(fade, 0.0, 1.0)

		var pos: Vector2 = piece["pos"]
		var w: float = float(piece["w"])
		var h: float = float(piece["h"])
		draw_set_transform(pos, float(piece["rot"]), Vector2.ONE)
		draw_rect(Rect2(-w * 0.5, -h * 0.5, w, h), color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
