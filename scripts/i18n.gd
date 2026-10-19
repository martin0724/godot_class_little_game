extends Node
## 轻量级双语支持（自动加载单例：I18n）。
## 用代码内置的字符串表做中/英切换，不依赖任何翻译资源文件。
## 用法：I18n.t("KEY") 或 I18n.t("KEY", [参数...])。

signal locale_changed(locale: String)

const SUPPORTED: Array[String] = ["zh", "en"]
const DEFAULT_LOCALE := "en"   ## 初始化 / 重置存档后的默认语言
const SETTING_KEY := "language"

## 各语言的自称（用于切换按钮显示“另一种语言”的名字）
const LOCALE_NAMES := {
	"zh": "中文",
	"en": "English",
}

## 字符串表：KEY -> { "zh": ..., "en": ... }
const STRINGS := {
	# —— 通用 ——
	"GAME_TITLE": {
		"zh": "潜艇大作战  ·  Submarine Race",
		"en": "Submarine Race",
	},
	"FINISH_LINE": {
		"zh": "终 点 线",
		"en": "F I N I S H",
	},
	"BTN_CANCEL": {
		"zh": "取消",
		"en": "Cancel",
	},
	"BTN_CONFIRM_RESET": {
		"zh": "确认重置",
		"en": "Confirm",
	},

	# —— 音效 / 语言 ——
	"BTN_SOUND_ON": {
		"zh": "音效：开",
		"en": "Sound: On",
	},
	"BTN_SOUND_OFF": {
		"zh": "音效：关",
		"en": "Sound: Off",
	},

	# —— 存档选择场景 ——
	"SAVE_SELECT_TITLE": {
		"zh": "潜艇大作战  ·  选择存档",
		"en": "Submarine Race  ·  Select Save",
	},
	"NEW_SAVE_TITLE": {
		"zh": "新建存档",
		"en": "New Save",
	},
	"SAVE_LIST_TITLE": {
		"zh": "存档列表",
		"en": "Save List",
	},
	"SAVE_NAME_LABEL": {
		"zh": "存档名称",
		"en": "Save Name",
	},
	"SAVE_NAME_PLACEHOLDER": {
		"zh": "存档 %d",
		"en": "Save %d",
	},
	"RENAME_SAVE_HINT": {
		"zh": "点击可修改存档名称",
		"en": "Click to rename this save",
	},
	"PLAYER_COUNT_LABEL": {
		"zh": "玩家数量",
		"en": "Players",
	},
	"TARGET_SCORE_LABEL": {
		"zh": "终点分数",
		"en": "Target Score",
	},
	"BTN_CREATE_START": {
		"zh": "创建并开始",
		"en": "Create & Start",
	},
	"BTN_ENTER": {
		"zh": "进入",
		"en": "Enter",
	},
	"BTN_DELETE": {
		"zh": "删除",
		"en": "Delete",
	},
	"NO_SAVES": {
		"zh": "还没有存档，先在左侧创建一个吧。",
		"en": "No saves yet — create one on the left.",
	},
	"SLOT_META": {
		"zh": "%d 名玩家 · 终点 %d 分 · 已进行 %d 局",
		"en": "%d players · target %d · %d matches",
	},
	"SLOT_UPDATED": {
		"zh": "上次更新：%s",
		"en": "Updated: %s",
	},
	"DELETE_SLOT_TITLE": {
		"zh": "删除存档",
		"en": "Delete Save",
	},
	"DELETE_SLOT_BODY": {
		"zh": "确定要删除存档「%s」吗？\n此操作不可撤销。",
		"en": "Delete save \"%s\"?\nThis cannot be undone.",
	},
	"CLEAR_ALL_TITLE": {
		"zh": "清空全部数据",
		"en": "Clear All Data",
	},
	"CLEAR_ALL_BODY": {
		"zh": "将删除所有存档并恢复默认配置（音效开启、静音关闭、语言英文）。\n此操作不可撤销。",
		"en": "Deletes every save and restores default settings (sound on, mute off, language English).\nThis cannot be undone.",
	},

	# —— 游戏内 ——
	"NAME_PLACEHOLDER": {
		"zh": "玩家名",
		"en": "Name",
	},
	"PLAYER_NAME": {
		"zh": "玩家%d",
		"en": "Player %d",
	},
	"STATUS_WINS": {
		"zh": "胜%d",
		"en": "W%d",
	},
	"BTN_RESET_SLOT": {
		"zh": "重置",
		"en": "Reset",
	},
	"RESET_SLOT_TITLE": {
		"zh": "重置当前存档",
		"en": "Reset Current Save",
	},
	"RESET_SLOT_BODY": {
		"zh": "将清空当前存档的分数与胜场，玩家名称会保留。\n此操作不可撤销。",
		"en": "Clears scores and wins of the current save. Player names are kept.\nThis cannot be undone.",
	},
	"BTN_BACK_TO_SAVES": {
		"zh": "存档",
		"en": "Save",
	},
	"BTN_SUMMON": {
		"zh": "召唤",
		"en": "Summon",
	},
	"WIN_TITLE": {
		"zh": "%s  获胜！",
		"en": "%s  wins!",
	},
	"WIN_SUBTITLE": {
		"zh": "抵达终点 · %d / %d",
		"en": "Reached the finish · %d / %d",
	},
	"WIN_RANK": {
		"zh": "本轮第 %d 名",
		"en": "Round rank #%d",
	},
	"ALL_FINISHED_TITLE": {
		"zh": "全员抵达终点！",
		"en": "All players finished!",
	},
	"ALL_FINISHED_BODY": {
		"zh": "本轮结束 · 共 %d 名玩家",
		"en": "Round over · %d players",
	},
	"WIN_STATS": {
		"zh": "累计胜场 %d ｜ 已完成对局 %d",
		"en": "Total wins %d  |  Matches %d",
	},
	"BTN_PLAY_AGAIN": {
		"zh": "再来一局",
		"en": "Play Again",
	},
}

var _locale := DEFAULT_LOCALE


func _ready() -> void:
	reload_settings()


## 从存档读取语言设置（重置存档后同步运行时状态用）。
func reload_settings() -> void:
	set_locale(str(DataStore.get_setting(SETTING_KEY, DEFAULT_LOCALE)), false)


func get_locale() -> String:
	return _locale


func set_locale(code: String, persist: bool = true) -> void:
	if not SUPPORTED.has(code):
		code = DEFAULT_LOCALE
	var changed := code != _locale
	_locale = code
	if persist:
		DataStore.set_setting(SETTING_KEY, code)
	if changed:
		locale_changed.emit(_locale)


## 在支持的语言之间循环切换。
func toggle() -> void:
	var index := SUPPORTED.find(_locale)
	set_locale(SUPPORTED[(index + 1) % SUPPORTED.size()])


## 切换按钮上显示的文字：显示“另一种”语言的名称。
func switch_button_text() -> String:
	var index := SUPPORTED.find(_locale)
	var next := SUPPORTED[(index + 1) % SUPPORTED.size()]
	return str(LOCALE_NAMES.get(next, next))


## 取翻译文本；args 非空时按 % 格式化。
func t(key: String, args: Array = []) -> String:
	var entry: Variant = STRINGS.get(key)
	if typeof(entry) != TYPE_DICTIONARY:
		return key
	var table: Dictionary = entry
	var text := str(table.get(_locale, table.get(DEFAULT_LOCALE, key)))
	if args.is_empty():
		return text
	return text % args
