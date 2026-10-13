extends Node2D
class_name Bubbles
## 轻量级水泡粒子效果。
## 不依赖任何贴图资源，直接使用 _draw() 绘制小圆点，向上飘升并淡出。

var _items: Array[Dictionary] = []


func _ready() -> void:
	set_process(false)


## 在 origin（本地坐标）处喷出一团气泡。
func burst(amount: int, origin: Vector2) -> void:
	for i in amount:
		var angle := randf() * TAU
		var radius := randf() * 18.0
		_items.append({
			"pos": origin + Vector2(cos(angle) * radius, randf_range(-8.0, 10.0)),
			"vel": Vector2(randf_range(-26.0, 26.0), randf_range(-82.0, -44.0)),
			"life": 0.0,
			"max_life": randf_range(0.55, 1.15),
			"radius": randf_range(1.8, 4.6),
		})
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	var alive: Array[Dictionary] = []
	for b in _items:
		b["life"] = float(b["life"]) + delta
		if float(b["life"]) < float(b["max_life"]):
			var pos: Vector2 = b["pos"]
			var vel: Vector2 = b["vel"]
			pos += vel * delta
			vel *= Vector2(0.985, 0.99)
			b["pos"] = pos
			b["vel"] = vel
			alive.append(b)
	_items = alive
	if _items.is_empty():
		set_process(false)
	queue_redraw()


func _draw() -> void:
	for b in _items:
		var t: float = float(b["life"]) / float(b["max_life"])
		var alpha: float = (1.0 - t) * 0.85
		var pos: Vector2 = b["pos"]
		var r: float = float(b["radius"])
		draw_circle(pos, r, Color(0.82, 0.95, 1.0, alpha))
		draw_arc(pos, r, 0.0, TAU, 14, Color(1.0, 1.0, 1.0, alpha), 1.0)
