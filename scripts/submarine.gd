extends Node2D
class_name Submarine
## 一艘卡通潜水艇，完全通过 _draw() 用矢量图形绘制，无需贴图资源。

const HULL_RX := 46.0  ## 艇身水平半径
const HULL_RY := 21.0  ## 艇身垂直半径

# —— 编号文字（位置：指挥塔上、艇身与潜望镜之间）——
# 旧版编号压在舷窗上互相干扰；新版移到指挥塔顶部、潜望镜左侧的空档。
# 潜望镜竖杆占 x:15..20，编号文字右缘必须控制在 x=+14 以内才不重叠。
const NUMBER_CENTER := Vector2(-6.0, -26.0)  ## 编号文字区域中心（相对艇身中心）
const NUMBER_FONT_SIZE := 16                 ## 编号字号
const NUMBER_BOX_W := 36.0                   ## 编号文字区域宽度（x: -24..+12）
const NUMBER_BOX_H := 22.0                   ## 编号文字区域高度

# 编号配色：白色字 + 深色描边，在指挥塔的深色底上同样清晰
const NUMBER_FONT_COLOR := Color(1, 1, 1, 0.98)
const NUMBER_OUTLINE_COLOR := Color(0.04, 0.07, 0.13, 0.9)
const NUMBER_OUTLINE_SIZE := 3

var number: int = 1
var racer_color: Color = Color.WHITE
var score: int = 0
var max_score: int = 20
var locked: bool = false      ## 已获胜锁定，不再接受加减分
var celebrating: bool = false ## 胜利金光效果
var pet_kind: int = 0         ## 头顶宠物造型（由主场景设置）

var home_x: float = 0.0       ## 该航道中心 x 坐标（由主场景设置）

var _target_y: float = 0.0
var _flash_color: Color = Color.WHITE
var _flash_amount: float = 0.0
var _time: float = 0.0
var _bubbles: Bubbles
var _number_label: Label
var _pet: Pet


func setup(p_number: int, p_color: Color, p_max: int) -> void:
	number = p_number
	racer_color = p_color
	max_score = p_max


func _ready() -> void:
	_bubbles = Bubbles.new()
	_bubbles.name = "Bubbles"
	add_child(_bubbles)

	_number_label = Label.new()
	_number_label.text = str(number)
	_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_number_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_number_label.position = NUMBER_CENTER - Vector2(NUMBER_BOX_W, NUMBER_BOX_H) * 0.5
	_number_label.size = Vector2(NUMBER_BOX_W, NUMBER_BOX_H)
	_number_label.add_theme_font_size_override("font_size", NUMBER_FONT_SIZE)
	_number_label.add_theme_color_override("font_color", NUMBER_FONT_COLOR)
	_number_label.add_theme_color_override("font_outline_color", NUMBER_OUTLINE_COLOR)
	_number_label.add_theme_constant_override("outline_size", NUMBER_OUTLINE_SIZE)
	add_child(_number_label)

	# 头顶宠物装饰
	_pet = Pet.new()
	_pet.name = "Pet"
	_pet.setup(pet_kind)
	add_child(_pet)

	set_process(true)
	queue_redraw()


## 设置上浮 / 下沉的目标高度（由主场景按格子数计算）。
func set_target_y(y: float) -> void:
	_target_y = y


## 得分闪烁反馈。
func flash(color: Color = Color.WHITE) -> void:
	_flash_color = color
	_flash_amount = 1.0


## 喷出水泡。
func burst(amount: int) -> void:
	if _bubbles:
		_bubbles.burst(amount, Vector2(randf_range(-22.0, 6.0), -HULL_RY))


func _process(delta: float) -> void:
	_time += delta
	# 平滑移向目标高度
	position.y = lerpf(position.y, _target_y, clampf(delta * 7.0, 0.0, 1.0))
	# 轻微左右摇摆，模拟漂浮
	position.x = home_x + sin(_time * 1.6 + float(number)) * 2.0

	if _flash_amount > 0.0:
		_flash_amount = maxf(0.0, _flash_amount - delta * 3.5)

	queue_redraw()


func _draw() -> void:
	var base := racer_color
	if celebrating:
		var pulse := (sin(_time * 8.0) + 1.0) * 0.5
		base = base.lerp(Color(1.0, 0.84, 0.25), 0.35 + pulse * 0.5)
	if _flash_amount > 0.0:
		base = base.lerp(_flash_color, clampf(_flash_amount, 0.0, 1.0) * 0.85)

	# 尾鳍 / 螺旋桨
	draw_colored_polygon(PackedVector2Array([
		Vector2(-HULL_RX + 6.0, -14.0),
		Vector2(-HULL_RX - 14.0, -22.0),
		Vector2(-HULL_RX - 14.0, 22.0),
		Vector2(-HULL_RX + 6.0, 14.0),
	]), base.darkened(0.25))

	# 指挥塔（围壳）
	draw_colored_polygon(PackedVector2Array([
		Vector2(-6.0, -HULL_RY - 16.0),
		Vector2(20.0, -HULL_RY - 16.0),
		Vector2(26.0, -HULL_RY + 4.0),
		Vector2(-10.0, -HULL_RY + 4.0),
	]), base.darkened(0.12))

	# 潜望镜（靠右，避免被头顶宠物遮挡）
	draw_rect(Rect2(15.0, -HULL_RY - 30.0, 5.0, 15.0), base.darkened(0.3))
	draw_rect(Rect2(11.0, -HULL_RY - 32.0, 14.0, 4.0), base.darkened(0.3))

	# 艇身
	draw_colored_polygon(_ellipse(Vector2.ZERO, HULL_RX, HULL_RY, 36), base)
	# 高光
	draw_colored_polygon(_ellipse(Vector2(-4.0, -7.0), HULL_RX * 0.72, HULL_RY * 0.42, 24), base.lightened(0.28))
	# 底部阴影
	draw_colored_polygon(_ellipse(Vector2(2.0, 9.0), HULL_RX * 0.82, HULL_RY * 0.32, 24), base.darkened(0.18))

	# 舷窗
	for i in 3:
		var px := -22.0 + float(i) * 18.0
		draw_circle(Vector2(px, -1.0), 5.0, Color(0.85, 0.96, 1.0))
		draw_arc(Vector2(px, -1.0), 5.0, 0.0, TAU, 18, base.darkened(0.4), 1.5)


func _ellipse(center: Vector2, rx: float, ry: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return pts
