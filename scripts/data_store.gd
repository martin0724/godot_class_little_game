extends Node
## 数据持久化（自动加载单例：DataStore）。
## 使用普通 JSON 文件保存玩家名称、分数、胜场等数据，位置：user://save_data.json
## 不依赖任何第三方插件。

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 1
const RACER_COUNT := 8

var _data: Dictionary = {}
var _loaded := false


func _init() -> void:
	_data = _default_data()


func _ready() -> void:
	load_data()


## 惰性加载：即使自动加载的 _ready 顺序不固定，
## 任何一次访问都会保证数据已从磁盘读出。
func _ensure_loaded() -> void:
	if not _loaded:
		load_data()


func _default_data() -> Dictionary:
	var players: Array = []
	for i in RACER_COUNT:
		players.append({
			# 空字符串 = “尚未自定义”，显示时按当前语言给出默认名
			"name": "",
			"score": 0,
			"wins": 0,
		})
	return {
		"version": SAVE_VERSION,
		"players": players,
		"matches_played": 0,
		"last_winner": -1,
		"settings": {
			"muted": false,
			"language": "en",
		},
	}


# ——————————————————— 读写 ———————————————————

func load_data() -> void:
	_loaded = true
	_data = _default_data()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_warning("DataStore: 无法读取存档 %s" % SAVE_PATH)
		return
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("DataStore: 存档内容无效，已回退到默认数据")
		return
	_merge(parsed)


## 把外部数据合并进默认结构，兼容缺字段 / 字段类型异常 / 版本变化。
func _merge(src: Dictionary) -> void:
	var players: Variant = src.get("players", [])
	if typeof(players) == TYPE_ARRAY:
		for i in mini((players as Array).size(), RACER_COUNT):
			var p: Variant = (players as Array)[i]
			if typeof(p) != TYPE_DICTIONARY:
				continue
			var dst: Dictionary = _data["players"][i]
			var loaded_name := str((p as Dictionary).get("name", dst["name"])).strip_edges()
			if not loaded_name.is_empty():
				dst["name"] = loaded_name
			dst["score"] = clampi(int((p as Dictionary).get("score", 0)), 0, 999999)
			dst["wins"] = maxi(0, int((p as Dictionary).get("wins", 0)))

	_data["matches_played"] = maxi(0, int(src.get("matches_played", 0)))
	_data["last_winner"] = clampi(int(src.get("last_winner", -1)), -1, RACER_COUNT - 1)

	var settings: Variant = src.get("settings", {})
	if typeof(settings) == TYPE_DICTIONARY:
		for key in (settings as Dictionary):
			_data["settings"][key] = (settings as Dictionary)[key]


func save_data() -> void:
	_ensure_loaded()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("DataStore: 无法写入存档 %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


# ——————————————————— 玩家 ———————————————————

func get_player_count() -> int:
	_ensure_loaded()
	return (_data["players"] as Array).size()


func get_player_name(index: int) -> String:
	_ensure_loaded()
	if index < 0 or index >= get_player_count():
		return ""
	return str(_data["players"][index]["name"])


func set_player_name(index: int, value: String) -> void:
	_ensure_loaded()
	if index < 0 or index >= get_player_count():
		return
	_data["players"][index]["name"] = value
	save_data()


func get_player_score(index: int) -> int:
	_ensure_loaded()
	if index < 0 or index >= get_player_count():
		return 0
	return int(_data["players"][index]["score"])


func set_player_score(index: int, value: int) -> void:
	_ensure_loaded()
	if index < 0 or index >= get_player_count():
		return
	_data["players"][index]["score"] = value
	save_data()


func get_player_wins(index: int) -> int:
	_ensure_loaded()
	if index < 0 or index >= get_player_count():
		return 0
	return int(_data["players"][index]["wins"])


## 记录一名玩家的胜利，同时累加对局数并记录最近胜者。
func record_win(index: int) -> void:
	_ensure_loaded()
	if index < 0 or index >= get_player_count():
		return
	_data["players"][index]["wins"] = get_player_wins(index) + 1
	_data["last_winner"] = index
	_data["matches_played"] = get_matches_played() + 1
	save_data()


func get_matches_played() -> int:
	_ensure_loaded()
	return int(_data["matches_played"])


func get_last_winner() -> int:
	_ensure_loaded()
	return int(_data["last_winner"])


## 新一局开始：只清零分数，保留名称与胜场。
func reset_scores() -> void:
	_ensure_loaded()
	for p in _data["players"]:
		p["score"] = 0
	save_data()


## 恢复出厂：清空全部数据。
func reset_all() -> void:
	_loaded = true
	_data = _default_data()
	save_data()


# ——————————————————— 设置 ———————————————————

func get_setting(key: String, default_value: Variant) -> Variant:
	_ensure_loaded()
	return (_data["settings"] as Dictionary).get(key, default_value)


func set_setting(key: String, value: Variant) -> void:
	_ensure_loaded()
	_data["settings"][key] = value
	save_data()
