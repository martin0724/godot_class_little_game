extends Node
## 数据持久化（自动加载单例：DataStore）。
## 使用普通 JSON 文件保存「存档槽（slot）」与全局设置，位置：user://save_data.json
## 不依赖任何第三方插件。
##
## 文件结构（v2）：
## {
##   "version": 2,
##   "settings": { "muted": false, "language": "en" },
##   "active_slot": "slot-...",
##   "slots": [ { id, name, player_count, max_score, created_at, updated_at,
##                matches_played, last_winner, players:[{name,score,wins}] } ]
## }

const SAVE_PATH := "user://save_data.json"
const SAVE_VERSION := 2

const PLAYER_MIN := 2
const PLAYER_MAX := 12
const TARGET_MIN := 5
const TARGET_MAX := 60
const MAX_SLOTS := 20
const SLOT_NAME_MAX_LEN := 20
const PLAYER_NAME_MAX_LEN := 12

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
	return {
		"version": SAVE_VERSION,
		"settings": {
			"muted": false,
			"language": "en",
		},
		"active_slot": "",
		"slots": [],
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


## 把外部数据合并进默认结构，兼容缺字段 / 字段类型异常 / 旧版本。
func _merge(src: Dictionary) -> void:
	# 全局设置（应用级，不属于任何存档槽）
	var settings: Variant = src.get("settings", {})
	if typeof(settings) == TYPE_DICTIONARY:
		for key in (settings as Dictionary):
			_data["settings"][key] = (settings as Dictionary)[key]

	var raw_slots: Variant = src.get("slots", null)
	if typeof(raw_slots) == TYPE_ARRAY:
		for raw in (raw_slots as Array):
			var slot := _sanitize_slot(raw)
			if not slot.is_empty() and (_data["slots"] as Array).size() < MAX_SLOTS:
				(_data["slots"] as Array).append(slot)
	elif typeof(src.get("players", null)) == TYPE_ARRAY:
		# v1 -> v2 迁移：把旧的“单存档”包装成一个存档槽
		var legacy_players: Array = src["players"]
		var count := clampi(legacy_players.size(), PLAYER_MIN, PLAYER_MAX)
		var slot := _make_slot("Default", count, 20)
		slot["players"] = _sanitize_players(legacy_players, count)
		slot["matches_played"] = maxi(0, int(src.get("matches_played", 0)))
		slot["last_winner"] = clampi(int(src.get("last_winner", -1)), -1, count - 1)
		(_data["slots"] as Array).append(slot)

	var active := str(src.get("active_slot", ""))
	if not active.is_empty() and _find_slot(active).is_empty():
		active = ""
	if active.is_empty() and not (_data["slots"] as Array).is_empty():
		active = str((_data["slots"] as Array)[0]["id"])
	_data["active_slot"] = active


func save_data() -> void:
	_ensure_loaded()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("DataStore: 无法写入存档 %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()


# ——————————————————— 数据结构辅助 ———————————————————

func _make_id() -> String:
	return "slot-%d-%d" % [int(Time.get_unix_time_from_system()), randi() % 100000]


func _now() -> String:
	return Time.get_datetime_string_from_system(false, true)


func _make_slot(slot_name: String, player_count: int, max_score: int) -> Dictionary:
	var count := clampi(player_count, PLAYER_MIN, PLAYER_MAX)
	var clean_name := slot_name.strip_edges()
	if clean_name.length() > SLOT_NAME_MAX_LEN:
		clean_name = clean_name.substr(0, SLOT_NAME_MAX_LEN)
	var now := _now()
	return {
		"id": _make_id(),
		"name": clean_name,
		"player_count": count,
		"max_score": clampi(max_score, TARGET_MIN, TARGET_MAX),
		"created_at": now,
		"updated_at": now,
		"matches_played": 0,
		"last_winner": -1,
		"players": _sanitize_players([], count),
	}


func _sanitize_players(raw: Variant, count: int) -> Array:
	var src: Array = raw if typeof(raw) == TYPE_ARRAY else []
	var out: Array = []
	for i in count:
		var player := {"name": "", "score": 0, "wins": 0}
		if i < src.size() and typeof(src[i]) == TYPE_DICTIONARY:
			var s: Dictionary = src[i]
			var nm := str(s.get("name", "")).strip_edges()
			if nm.length() > PLAYER_NAME_MAX_LEN:
				nm = nm.substr(0, PLAYER_NAME_MAX_LEN)
			player["name"] = nm
			player["score"] = clampi(int(s.get("score", 0)), 0, 999999)
			player["wins"] = maxi(0, int(s.get("wins", 0)))
		out.append(player)
	return out


func _sanitize_slot(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var s: Dictionary = raw
	var count := clampi(int(s.get("player_count", 8)), PLAYER_MIN, PLAYER_MAX)
	return {
		"id": str(s.get("id", "")).strip_edges() if not str(s.get("id", "")).is_empty() else _make_id(),
		"name": str(s.get("name", "")).strip_edges(),
		"player_count": count,
		"max_score": clampi(int(s.get("max_score", 20)), TARGET_MIN, TARGET_MAX),
		"created_at": str(s.get("created_at", "")),
		"updated_at": str(s.get("updated_at", "")),
		"matches_played": maxi(0, int(s.get("matches_played", 0))),
		"last_winner": clampi(int(s.get("last_winner", -1)), -1, count - 1),
		"players": _sanitize_players(s.get("players", []), count),
	}


func _find_slot(id: String) -> Dictionary:
	_ensure_loaded()
	for slot in (_data["slots"] as Array):
		if str(slot["id"]) == id:
			return slot
	return {}


func _touch(slot: Dictionary) -> void:
	slot["updated_at"] = _now()


# ——————————————————— 存档槽管理 ———————————————————

func get_slot_count() -> int:
	_ensure_loaded()
	return (_data["slots"] as Array).size()


func get_slot_limit() -> int:
	return MAX_SLOTS


## 供 UI 列表使用的摘要（副本，避免外部误改内部数据）。
func get_slot_summaries() -> Array:
	_ensure_loaded()
	var out: Array = []
	for slot in (_data["slots"] as Array):
		out.append({
			"id": slot["id"],
			"name": slot["name"],
			"player_count": slot["player_count"],
			"max_score": slot["max_score"],
			"matches_played": slot["matches_played"],
			"updated_at": slot["updated_at"],
		})
	return out


## 新建存档槽并设为当前存档，返回其 id（失败返回空串）。
func create_slot(slot_name: String, player_count: int, max_score: int) -> String:
	_ensure_loaded()
	if get_slot_count() >= MAX_SLOTS:
		return ""
	var slot := _make_slot(slot_name, player_count, max_score)
	(_data["slots"] as Array).append(slot)
	_data["active_slot"] = str(slot["id"])
	save_data()
	return str(slot["id"])


func has_slot(id: String) -> bool:
	return not _find_slot(id).is_empty()


## 修改存档名称（允许传空串表示“未命名”，由界面展示默认名）。
func rename_slot(id: String, new_name: String) -> bool:
	_ensure_loaded()
	var slot := _find_slot(id)
	if slot.is_empty():
		return false
	var clean := new_name.strip_edges()
	if clean.length() > SLOT_NAME_MAX_LEN:
		clean = clean.substr(0, SLOT_NAME_MAX_LEN)
	if str(slot["name"]) == clean:
		return true
	slot["name"] = clean
	_touch(slot)
	save_data()
	return true


func delete_slot(id: String) -> bool:
	_ensure_loaded()
	var slots: Array = _data["slots"]
	for i in slots.size():
		if str(slots[i]["id"]) == id:
			slots.remove_at(i)
			if str(_data["active_slot"]) == id:
				_data["active_slot"] = ""
			save_data()
			return true
	return false


func set_active_slot(id: String) -> bool:
	_ensure_loaded()
	if not has_slot(id):
		return false
	_data["active_slot"] = id
	save_data()
	return true


func clear_active_slot() -> void:
	_ensure_loaded()
	_data["active_slot"] = ""
	save_data()


func get_active_slot_id() -> String:
	_ensure_loaded()
	return str(_data["active_slot"])


func has_active_slot() -> bool:
	return not get_active_slot().is_empty()


## 返回当前存档槽（内部引用，可直接修改后调用 save_data()）。
func get_active_slot() -> Dictionary:
	_ensure_loaded()
	var id := str(_data["active_slot"])
	if id.is_empty():
		return {}
	return _find_slot(id)


func get_active_slot_name() -> String:
	return str(get_active_slot().get("name", ""))


func get_active_player_count() -> int:
	var slot := get_active_slot()
	return int(slot.get("player_count", 0))


func get_active_max_score() -> int:
	var slot := get_active_slot()
	return int(slot.get("max_score", 20))


## 清空当前存档的进度（分数 / 胜场 / 对局数），**保留玩家名称**与存档本身的设置。
func reset_active_slot() -> void:
	var slot := get_active_slot()
	if slot.is_empty():
		return
	# 先沿用现有玩家列表（保留名称），再把分数与胜场清零
	var players := _sanitize_players(slot["players"], int(slot["player_count"]))
	for player in players:
		player["score"] = 0
		player["wins"] = 0
	slot["players"] = players
	slot["matches_played"] = 0
	slot["last_winner"] = -1
	_touch(slot)
	save_data()


## 恢复出厂：删除全部存档并重置所有设置。
func clear_all() -> void:
	_loaded = true
	_data = _default_data()
	save_data()


# ——————————————————— 当前存档的玩家数据 ———————————————————

func get_player_count() -> int:
	var slot := get_active_slot()
	if slot.is_empty():
		return 0
	return (slot["players"] as Array).size()


func _players() -> Array:
	var slot := get_active_slot()
	return slot["players"] if not slot.is_empty() else []


func get_player_name(index: int) -> String:
	var players := _players()
	if index < 0 or index >= players.size():
		return ""
	return str(players[index]["name"])


func set_player_name(index: int, value: String) -> void:
	var players := _players()
	if index < 0 or index >= players.size():
		return
	players[index]["name"] = value
	_touch(get_active_slot())
	save_data()


func get_player_score(index: int) -> int:
	var players := _players()
	if index < 0 or index >= players.size():
		return 0
	return int(players[index]["score"])


func set_player_score(index: int, value: int) -> void:
	var players := _players()
	if index < 0 or index >= players.size():
		return
	players[index]["score"] = value
	_touch(get_active_slot())
	save_data()


func get_player_wins(index: int) -> int:
	var players := _players()
	if index < 0 or index >= players.size():
		return 0
	return int(players[index]["wins"])


## 记录一名玩家的胜利，同时累加对局数并记录最近胜者。
func record_win(index: int) -> void:
	var slot := get_active_slot()
	if slot.is_empty():
		return
	var players: Array = slot["players"]
	if index < 0 or index >= players.size():
		return
	players[index]["wins"] = int(players[index]["wins"]) + 1
	slot["last_winner"] = index
	slot["matches_played"] = int(slot["matches_played"]) + 1
	_touch(slot)
	save_data()


func get_matches_played() -> int:
	return int(get_active_slot().get("matches_played", 0))


func get_last_winner() -> int:
	return int(get_active_slot().get("last_winner", -1))


## 新一局开始：只清零分数，保留名称与胜场。
func reset_scores() -> void:
	var slot := get_active_slot()
	if slot.is_empty():
		return
	for player in (slot["players"] as Array):
		player["score"] = 0
	_touch(slot)
	save_data()


# ——————————————————— 全局设置 ———————————————————

func get_setting(key: String, default_value: Variant) -> Variant:
	_ensure_loaded()
	return (_data["settings"] as Dictionary).get(key, default_value)


func set_setting(key: String, value: Variant) -> void:
	_ensure_loaded()
	_data["settings"][key] = value
	save_data()
