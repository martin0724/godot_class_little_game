extends Node2D
class_name Pet
## 潜艇头顶的宠物装饰（纯矢量绘制，无需贴图）。
## 共 20 种造型，玩家数量 ≤ 20 时每人一只、互不重复（潜艇最多 12 名玩家）。

enum Kind {
	PENGUIN, ALIEN, OCTOPUS, CRAB, FISH,
	STARFISH, JELLYFISH, CAT, DOG, RABBIT,
	FROG, TURTLE, PIG, PANDA, DUCK,
	BEE, SNAIL, GHOST, ROBOT, SEAL,
}

const BASE_Y := -52.0  ## 相对潜艇中心的高度

var kind: int = Kind.PENGUIN
var _time: float = 0.0


func setup(p_kind: int) -> void:
	kind = posmod(p_kind, Kind.size())


func _ready() -> void:
	position = Vector2(0, BASE_Y)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_time += delta
	# 轻微上下浮动 + 左右摇摆
	position.y = BASE_Y + sin(_time * 3.2) * 1.6
	rotation = sin(_time * 2.1) * 0.07
	queue_redraw()


func _draw() -> void:
	match kind:
		Kind.PENGUIN: _penguin()
		Kind.ALIEN: _alien()
		Kind.OCTOPUS: _octopus()
		Kind.CRAB: _crab()
		Kind.FISH: _fish()
		Kind.STARFISH: _starfish()
		Kind.JELLYFISH: _jellyfish()
		Kind.CAT: _cat()
		Kind.DOG: _dog()
		Kind.RABBIT: _rabbit()
		Kind.FROG: _frog()
		Kind.TURTLE: _turtle()
		Kind.PIG: _pig()
		Kind.PANDA: _panda()
		Kind.DUCK: _duck()
		Kind.BEE: _bee()
		Kind.SNAIL: _snail()
		Kind.GHOST: _ghost()
		Kind.ROBOT: _robot()
		Kind.SEAL: _seal()


# ——————————————————— 各种宠物 ———————————————————

func _penguin() -> void:
	var body := Color(0.16, 0.18, 0.24)
	var white := Color(0.97, 0.97, 0.99)
	var orange := Color(1.0, 0.62, 0.12)
	var dark := Color(0.05, 0.05, 0.08)
	# 翅膀
	draw_colored_polygon(_ellipse(Vector2(-12, 2), 4.2, 8.0, 16), body)
	draw_colored_polygon(_ellipse(Vector2(12, 2), 4.2, 8.0, 16), body)
	# 身体 + 肚皮
	draw_colored_polygon(_ellipse(Vector2(0, 1), 12.5, 15.0, 26), body)
	draw_colored_polygon(_ellipse(Vector2(0, 3.5), 8.5, 10.5, 22), white)
	# 眼睛
	draw_circle(Vector2(-4.2, -5.0), 2.7, white)
	draw_circle(Vector2(4.2, -5.0), 2.7, white)
	draw_circle(Vector2(-4.0, -4.8), 1.5, dark)
	draw_circle(Vector2(4.4, -4.8), 1.5, dark)
	# 嘴 + 脚
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -1), Vector2(3, -1), Vector2(0, 3.4)]), orange)
	draw_colored_polygon(_ellipse(Vector2(-5, 15.5), 5.0, 2.6, 14), orange)
	draw_colored_polygon(_ellipse(Vector2(5, 15.5), 5.0, 2.6, 14), orange)


func _alien() -> void:
	var green := Color(0.45, 0.85, 0.35)
	var dark := Color(0.08, 0.12, 0.10)
	# 触角
	draw_line(Vector2(-3, -11), Vector2(-6.5, -18), green, 2.0)
	draw_line(Vector2(3, -11), Vector2(6.5, -18), green, 2.0)
	draw_circle(Vector2(-6.5, -19.5), 2.5, Color(1.0, 0.85, 0.2))
	draw_circle(Vector2(6.5, -19.5), 2.5, Color(1.0, 0.85, 0.2))
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 0), 13.0, 14.0, 28), green)
	# 大眼睛
	draw_colored_polygon(_ellipse(Vector2(-5, -1), 5.0, 6.8, 20), dark)
	draw_colored_polygon(_ellipse(Vector2(5, -1), 5.0, 6.8, 20), dark)
	draw_circle(Vector2(-6.2, -2.6), 1.5, Color(1, 1, 1))
	draw_circle(Vector2(3.8, -2.6), 1.5, Color(1, 1, 1))
	# 嘴
	draw_line(Vector2(-3, 8), Vector2(3, 8), dark, 1.5)


func _octopus() -> void:
	var purple := Color(0.72, 0.42, 0.85)
	var dark := Color(0.06, 0.05, 0.09)
	# 触手
	for lx in [-10.0, -5.0, 0.0, 5.0, 10.0]:
		draw_colored_polygon(_ellipse(Vector2(lx, 11.0), 3.4, 6.0, 14), purple.darkened(0.12))
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 0), 13.0, 12.0, 26), purple)
	# 眼睛
	draw_circle(Vector2(-4.5, -2.0), 3.4, Color(1, 1, 1))
	draw_circle(Vector2(4.5, -2.0), 3.4, Color(1, 1, 1))
	draw_circle(Vector2(-4.5, -1.5), 1.7, dark)
	draw_circle(Vector2(4.5, -1.5), 1.7, dark)
	# 腮红
	draw_circle(Vector2(-9, 3.5), 2.2, Color(1, 0.6, 0.75, 0.7))
	draw_circle(Vector2(9, 3.5), 2.2, Color(1, 0.6, 0.75, 0.7))


func _crab() -> void:
	var red := Color(0.92, 0.32, 0.26)
	var dark := Color(0.06, 0.06, 0.08)
	var white := Color(1, 1, 1)
	# 腿
	for s in [-1.0, 1.0]:
		for k in 3:
			draw_line(
				Vector2(s * 10.0, 1.0 + float(k) * 3.2),
				Vector2(s * (16.0 + float(k) * 1.5), 3.5 + float(k) * 3.6),
				red.darkened(0.18), 2.0
			)
	# 身体
	draw_colored_polygon(_ellipse(Vector2(0, 2), 13.0, 9.5, 24), red)
	# 钳子
	draw_circle(Vector2(-15, -6), 5.0, red.darkened(0.05))
	draw_circle(Vector2(15, -6), 5.0, red.darkened(0.05))
	draw_colored_polygon(PackedVector2Array([
		Vector2(-17.5, -8.5), Vector2(-12.5, -8.5), Vector2(-15, -3.5)
	]), red.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([
		Vector2(17.5, -8.5), Vector2(12.5, -8.5), Vector2(15, -3.5)
	]), red.darkened(0.3))
	# 眼柄 + 眼睛
	draw_line(Vector2(-4, -6), Vector2(-4, -13), red, 2.0)
	draw_line(Vector2(4, -6), Vector2(4, -13), red, 2.0)
	draw_circle(Vector2(-4, -14), 2.7, white)
	draw_circle(Vector2(4, -14), 2.7, white)
	draw_circle(Vector2(-4, -14), 1.4, dark)
	draw_circle(Vector2(4, -14), 1.4, dark)
	# 嘴
	draw_line(Vector2(-3, 7), Vector2(3, 7), dark, 1.4)


func _fish() -> void:
	var orange := Color(1.0, 0.58, 0.18)
	var white := Color(1, 1, 1)
	var dark := Color(0.06, 0.06, 0.08)
	# 尾巴
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -6), Vector2(-19, -11), Vector2(-19, 11), Vector2(-10, 6)
	]), orange.darkened(0.18))
	# 背鳍
	draw_colored_polygon(PackedVector2Array([Vector2(-3, -9), Vector2(3, -15), Vector2(7, -8)]), orange.darkened(0.15))
	# 身体
	draw_colored_polygon(_ellipse(Vector2(0, 0), 13.0, 9.5, 24), orange)
	# 条纹
	draw_line(Vector2(-2, -7), Vector2(-2, 7), white, 2.2)
	# 眼睛
	draw_circle(Vector2(5.5, -2.0), 3.2, white)
	draw_circle(Vector2(6.0, -2.0), 1.7, dark)
	# 嘴
	draw_line(Vector2(11.5, 2.5), Vector2(15, 3.5), orange.darkened(0.35), 1.6)


func _starfish() -> void:
	var col := Color(1.0, 0.55, 0.65)
	var dark := Color(0.1, 0.08, 0.12)
	# 五角星（从中心做三角扇，保证凹多边形也能正确渲染）
	var pts := PackedVector2Array()
	for i in 10:
		var r := 15.0 if i % 2 == 0 else 6.6
		var a := -PI * 0.5 + PI * float(i) / 5.0
		pts.append(Vector2(cos(a) * r, sin(a) * r))
	var prev := pts[pts.size() - 1]
	for p in pts:
		draw_colored_polygon(PackedVector2Array([Vector2(0, 0), prev, p]), col)
		prev = p
	# 表情
	draw_circle(Vector2(-3.2, -2.0), 2.0, dark)
	draw_circle(Vector2(3.2, -2.0), 2.0, dark)
	draw_circle(Vector2(0, 4.0), 1.6, Color(1, 1, 1, 0.9))


func _jellyfish() -> void:
	var col := Color(0.98, 0.62, 0.86)
	var col2 := Color(0.86, 0.45, 0.78)
	var dark := Color(0.1, 0.08, 0.12)
	# 触须
	for k in 4:
		var x := -7.5 + float(k) * 5.0
		var sway := sin(_time * 4.0 + float(k) * 1.3) * 2.0
		draw_line(Vector2(x, 6.0), Vector2(x + sway, 18.0), col2, 2.2)
	# 伞盖
	draw_colored_polygon(_ellipse(Vector2(0, 0), 12.5, 11.0, 26), col)
	# 眼睛
	draw_circle(Vector2(-4.2, -2.0), 2.9, Color(1, 1, 1))
	draw_circle(Vector2(4.2, -2.0), 2.9, Color(1, 1, 1))
	draw_circle(Vector2(-4.2, -1.6), 1.5, dark)
	draw_circle(Vector2(4.2, -1.6), 1.5, dark)
	# 腮红
	draw_circle(Vector2(-8.0, 3.5), 2.0, Color(1, 0.5, 0.7, 0.6))
	draw_circle(Vector2(8.0, 3.5), 2.0, Color(1, 0.5, 0.7, 0.6))


func _cat() -> void:
	var fur := Color(0.98, 0.85, 0.55)
	var dark := Color(0.12, 0.1, 0.12)
	var white := Color(1, 1, 1)
	# 耳朵
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -6), Vector2(-6, -17), Vector2(-1, -7)]), fur.darkened(0.06))
	draw_colored_polygon(PackedVector2Array([Vector2(1, -7), Vector2(6, -17), Vector2(11, -6)]), fur.darkened(0.06))
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -7), Vector2(-6, -14), Vector2(-3, -7)]), Color(1, 0.6, 0.7))
	draw_colored_polygon(PackedVector2Array([Vector2(3, -7), Vector2(6, -14), Vector2(9, -7)]), Color(1, 0.6, 0.7))
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 1), 12.5, 11.5, 26), fur)
	# 眼睛
	draw_colored_polygon(_ellipse(Vector2(-4.6, -1), 2.6, 3.2, 16), dark)
	draw_colored_polygon(_ellipse(Vector2(4.6, -1), 2.6, 3.2, 16), dark)
	draw_circle(Vector2(-4.0, -2.2), 1.0, white)
	draw_circle(Vector2(5.2, -2.2), 1.0, white)
	# 鼻子
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 4), Vector2(2, 4), Vector2(0, 6.5)]), Color(1, 0.55, 0.63))
	# 胡须
	for s in [-1.0, 1.0]:
		draw_line(Vector2(s * 3, 5), Vector2(s * 13, 3), Color(1, 1, 1, 0.75), 1.0)
		draw_line(Vector2(s * 3, 6.5), Vector2(s * 13, 7.5), Color(1, 1, 1, 0.75), 1.0)


func _dog() -> void:
	var fur := Color(0.80, 0.60, 0.36)
	var muzzle := Color(0.96, 0.90, 0.82)
	var dark := Color(0.14, 0.10, 0.08)
	var white := Color(1, 1, 1)
	# 垂耳
	draw_colored_polygon(_ellipse(Vector2(-12, -3), 5.0, 9.5, 16), fur.darkened(0.18))
	draw_colored_polygon(_ellipse(Vector2(12, -3), 5.0, 9.5, 16), fur.darkened(0.18))
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 1), 12.0, 11.0, 26), fur)
	# 口鼻
	draw_colored_polygon(_ellipse(Vector2(0, 6), 6.5, 5.0, 18), muzzle)
	draw_circle(Vector2(0, 4.0), 2.4, dark)
	# 眼睛
	draw_circle(Vector2(-4.6, -2.0), 2.2, dark)
	draw_circle(Vector2(4.6, -2.0), 2.2, dark)
	draw_circle(Vector2(-4.0, -2.6), 0.9, white)
	draw_circle(Vector2(5.2, -2.6), 0.9, white)


func _rabbit() -> void:
	var fur := Color(0.96, 0.94, 0.98)
	var pink := Color(1.0, 0.66, 0.76)
	var dark := Color(0.16, 0.12, 0.16)
	# 长耳
	draw_colored_polygon(_ellipse(Vector2(-6, -14), 3.6, 9.5, 14), fur)
	draw_colored_polygon(_ellipse(Vector2(6, -14), 3.6, 9.5, 14), fur)
	draw_colored_polygon(_ellipse(Vector2(-6, -14), 1.8, 6.5, 12), pink)
	draw_colored_polygon(_ellipse(Vector2(6, -14), 1.8, 6.5, 12), pink)
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 1), 11.5, 10.5, 26), fur)
	# 眼睛 / 鼻子
	draw_circle(Vector2(-4.2, -1.5), 2.1, dark)
	draw_circle(Vector2(4.2, -1.5), 2.1, dark)
	draw_colored_polygon(PackedVector2Array([Vector2(-2, 3.5), Vector2(2, 3.5), Vector2(0, 5.5)]), pink)
	# 胡须
	for s in [-1.0, 1.0]:
		draw_line(Vector2(s * 3, 4), Vector2(s * 12, 2.5), Color(1, 1, 1, 0.7), 1.0)
		draw_line(Vector2(s * 3, 5), Vector2(s * 12, 6.5), Color(1, 1, 1, 0.7), 1.0)


func _frog() -> void:
	var green := Color(0.44, 0.82, 0.42)
	var dark := Color(0.10, 0.16, 0.10)
	var white := Color(1, 1, 1)
	# 头顶眼包
	draw_circle(Vector2(-6.5, -8.5), 5.6, green)
	draw_circle(Vector2(6.5, -8.5), 5.6, green)
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 2), 13.5, 10.5, 28), green)
	# 眼睛
	draw_circle(Vector2(-6.5, -9.0), 3.6, white)
	draw_circle(Vector2(6.5, -9.0), 3.6, white)
	draw_circle(Vector2(-6.5, -9.0), 1.9, dark)
	draw_circle(Vector2(6.5, -9.0), 1.9, dark)
	# 大嘴 + 腮红
	draw_line(Vector2(-7, 5.5), Vector2(7, 5.5), dark, 1.8)
	draw_circle(Vector2(-9.8, 3), 2.0, Color(1, 0.6, 0.65, 0.55))
	draw_circle(Vector2(9.8, 3), 2.0, Color(1, 0.6, 0.65, 0.55))


func _turtle() -> void:
	var shell := Color(0.30, 0.62, 0.42)
	var shell_hi := Color(0.45, 0.78, 0.55)
	var skin := Color(0.72, 0.86, 0.55)
	var dark := Color(0.10, 0.14, 0.10)
	# 前鳍
	draw_colored_polygon(_ellipse(Vector2(-13, 7), 5.5, 3.2, 12), skin)
	draw_colored_polygon(_ellipse(Vector2(13, 7), 5.5, 3.2, 12), skin)
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, -9), 7.2, 6.6, 20), skin)
	draw_circle(Vector2(-2.8, -9.6), 1.7, dark)
	draw_circle(Vector2(2.8, -9.6), 1.7, dark)
	# 龟壳
	draw_colored_polygon(_ellipse(Vector2(0, 4), 13.5, 10.0, 28), shell)
	draw_colored_polygon(_ellipse(Vector2(0, 3), 9.0, 6.4, 22), shell_hi)
	draw_line(Vector2(0, -3), Vector2(0, 10), shell.darkened(0.22), 1.6)
	draw_line(Vector2(-9, 4), Vector2(9, 4), shell.darkened(0.22), 1.6)


func _pig() -> void:
	var skin := Color(1.0, 0.72, 0.78)
	var snout := Color(1.0, 0.62, 0.70)
	var dark := Color(0.20, 0.10, 0.14)
	# 尖耳
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -6), Vector2(-4, -13), Vector2(-3, -5)]), skin.darkened(0.10))
	draw_colored_polygon(PackedVector2Array([Vector2(11, -6), Vector2(4, -13), Vector2(3, -5)]), skin.darkened(0.10))
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 1), 12.5, 11.5, 26), skin)
	# 猪鼻
	draw_colored_polygon(_ellipse(Vector2(0, 5.5), 5.8, 4.2, 18), snout)
	draw_circle(Vector2(-2.0, 5.5), 1.2, dark)
	draw_circle(Vector2(2.0, 5.5), 1.2, dark)
	# 眼睛
	draw_circle(Vector2(-4.8, -2.5), 1.9, dark)
	draw_circle(Vector2(4.8, -2.5), 1.9, dark)


func _panda() -> void:
	var white := Color(0.97, 0.97, 0.99)
	var black := Color(0.12, 0.12, 0.15)
	# 圆耳
	draw_circle(Vector2(-9, -8), 5.0, black)
	draw_circle(Vector2(9, -8), 5.0, black)
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 1), 12.5, 11.5, 26), white)
	# 黑眼圈
	draw_colored_polygon(_ellipse(Vector2(-4.8, -1.5), 4.0, 5.0, 16), black)
	draw_colored_polygon(_ellipse(Vector2(4.8, -1.5), 4.0, 5.0, 16), black)
	draw_circle(Vector2(-4.8, -1.5), 1.9, white)
	draw_circle(Vector2(4.8, -1.5), 1.9, white)
	# 鼻子 + 嘴
	draw_circle(Vector2(0, 3.5), 1.8, black)
	draw_line(Vector2(0, 5.2), Vector2(0, 7.0), black, 1.3)


func _duck() -> void:
	var body := Color(1.0, 0.86, 0.30)
	var orange := Color(1.0, 0.58, 0.16)
	var dark := Color(0.16, 0.12, 0.08)
	# 呆毛
	draw_colored_polygon(PackedVector2Array([Vector2(-2, -9), Vector2(2, -15), Vector2(5, -9)]), body.darkened(0.08))
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, 2), 12.0, 11.0, 26), body)
	# 嘴
	draw_colored_polygon(_ellipse(Vector2(0, 6.5), 6.5, 3.4, 16), orange)
	draw_line(Vector2(-6, 6.5), Vector2(6, 6.5), orange.darkened(0.25), 1.2)
	# 眼睛
	draw_circle(Vector2(-4.4, -2.0), 2.1, dark)
	draw_circle(Vector2(4.4, -2.0), 2.1, dark)
	draw_circle(Vector2(-3.8, -2.7), 0.8, Color(1, 1, 1))
	draw_circle(Vector2(5.0, -2.7), 0.8, Color(1, 1, 1))


func _bee() -> void:
	var yellow := Color(1.0, 0.84, 0.25)
	var black := Color(0.14, 0.12, 0.16)
	var wing := Color(0.85, 0.94, 1.0, 0.85)
	# 翅膀
	draw_colored_polygon(_ellipse(Vector2(-8, -9), 6.0, 3.6, 14), wing)
	draw_colored_polygon(_ellipse(Vector2(8, -9), 6.0, 3.6, 14), wing)
	# 触角
	draw_line(Vector2(-3, -11), Vector2(-5.5, -17), black, 1.6)
	draw_line(Vector2(3, -11), Vector2(5.5, -17), black, 1.6)
	draw_circle(Vector2(-5.5, -18), 1.8, black)
	draw_circle(Vector2(5.5, -18), 1.8, black)
	# 身体
	draw_colored_polygon(_ellipse(Vector2(0, 2), 11.5, 12.0, 26), yellow)
	# 条纹
	draw_line(Vector2(-10, -2), Vector2(10, -2), black, 2.6)
	draw_line(Vector2(-11, 4), Vector2(11, 4), black, 2.6)
	# 眼睛 + 微笑
	draw_circle(Vector2(-4.6, -6.0), 2.0, black)
	draw_circle(Vector2(4.6, -6.0), 2.0, black)
	draw_arc(Vector2(0, 5.8), 3.4, 0.25, PI - 0.25, 12, black, 1.4)


func _snail() -> void:
	var shell := Color(0.86, 0.55, 0.35)
	var shell_dark := Color(0.68, 0.38, 0.22)
	var body := Color(0.94, 0.86, 0.68)
	var dark := Color(0.14, 0.10, 0.08)
	# 身体
	draw_colored_polygon(_ellipse(Vector2(2, 8), 13.0, 5.5, 20), body)
	# 壳（同心弧→ 螺旋感）
	draw_circle(Vector2(-3, 0), 10.0, shell)
	draw_arc(Vector2(-3, 0), 6.2, 0.0, TAU, 20, shell_dark, 1.8)
	draw_arc(Vector2(-3, 0), 3.0, 0.0, TAU, 16, shell_dark, 1.4)
	# 眼柄
	draw_line(Vector2(7, 4), Vector2(11, -5), body, 2.0)
	draw_line(Vector2(10, 4), Vector2(14, -4), body, 2.0)
	draw_circle(Vector2(11, -6.5), 1.9, dark)
	draw_circle(Vector2(14, -5.5), 1.9, dark)


func _ghost() -> void:
	var body := Color(0.90, 0.94, 1.0)
	var dark := Color(0.14, 0.16, 0.24)
	# 圆顶（凸多边形，从左侧起接上半圆，最后自动闭合底边）
	var dome := PackedVector2Array()
	dome.append(Vector2(-11.5, 7.0))
	for i in range(1, 19):
		var a := PI * float(i) / 18.0
		dome.append(Vector2(-cos(a) * 11.5, 7.0 - sin(a) * 17.0))
	draw_colored_polygon(dome, body)
	# 波浪下摆
	draw_circle(Vector2(-7.5, 6.0), 4.2, body)
	draw_circle(Vector2(0.0, 7.5), 4.4, body)
	draw_circle(Vector2(7.5, 6.0), 4.2, body)
	# 眼睛 + 嘴
	draw_colored_polygon(_ellipse(Vector2(-4.0, -3.0), 2.0, 3.0, 14), dark)
	draw_colored_polygon(_ellipse(Vector2(4.0, -3.0), 2.0, 3.0, 14), dark)
	draw_circle(Vector2(0, 3.0), 2.2, dark)


func _robot() -> void:
	var metal := Color(0.72, 0.80, 0.90)
	var metal_dark := Color(0.50, 0.58, 0.70)
	var glow := Color(0.35, 0.95, 0.85)
	var screen := Color(0.12, 0.16, 0.22)
	# 天线
	draw_line(Vector2(0, -10), Vector2(0, -17), metal_dark, 2.0)
	draw_circle(Vector2(0, -18.5), 2.4, glow)
	# 方头外壳
	draw_rect(Rect2(-11, -10, 22, 20), metal)
	draw_rect(Rect2(-11, -10, 22, 20), metal_dark, false, 1.6)
	# 屏幕脸
	draw_rect(Rect2(-7.5, -6.5, 15, 11), screen)
	# 眼睛
	draw_circle(Vector2(-4.0, -1.0), 2.2, glow)
	draw_circle(Vector2(4.0, -1.0), 2.2, glow)
	# 嘴（三个小方格）
	for i in 3:
		draw_rect(Rect2(-4.6 + float(i) * 3.4, 3.4, 2.2, 2.2), glow)


func _seal() -> void:
	var body := Color(0.66, 0.72, 0.80)
	var belly := Color(0.86, 0.90, 0.95)
	var dark := Color(0.10, 0.12, 0.16)
	# 身体
	draw_colored_polygon(_ellipse(Vector2(0, 5), 13.0, 9.5, 24), body)
	# 头
	draw_colored_polygon(_ellipse(Vector2(0, -5), 10.5, 9.5, 24), body)
	# 肚皮
	draw_colored_polygon(_ellipse(Vector2(0, 6), 8.0, 6.0, 20), belly)
	# 眼睛
	draw_circle(Vector2(-4.2, -6.0), 2.3, dark)
	draw_circle(Vector2(4.2, -6.0), 2.3, dark)
	draw_circle(Vector2(-3.6, -6.7), 0.9, Color(1, 1, 1))
	draw_circle(Vector2(4.8, -6.7), 0.9, Color(1, 1, 1))
	# 鼻子
	draw_colored_polygon(PackedVector2Array([Vector2(-2.2, 0.0), Vector2(2.2, 0.0), Vector2(0, 2.6)]), dark)
	# 胡须
	for s in [-1.0, 1.0]:
		draw_line(Vector2(s * 2.5, 1.5), Vector2(s * 11, 0.0), Color(1, 1, 1, 0.6), 1.0)
		draw_line(Vector2(s * 2.5, 2.5), Vector2(s * 11, 4.0), Color(1, 1, 1, 0.6), 1.0)


func _ellipse(center: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
