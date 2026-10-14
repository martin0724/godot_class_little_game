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
	"GAME_TITLE": {
		"zh": "潜艇大作战  ·  Submarine Race",
		"en": "Submarine Race",
	},
	"FINISH_LINE": {
		"zh": "终 点 线",
		"en": "F I N I S H",
	},
	"BTN_SOUND_ON": {
		"zh": "音效：开",
		"en": "Sound: On",
	},
	"BTN_SOUND_OFF": {
		"zh": "音效：关",
		"en": "Sound: Off",
	},
	"BTN_RESET": {
		"zh": "重置存档",
		"en": "Reset Data",
	},
	"BTN_PLAY_AGAIN": {
		"zh": "再来一局",
		"en": "Play Again",
	},
	"BTN_CANCEL": {
		"zh": "取消",
		"en": "Cancel",
	},
	"BTN_CONFIRM_RESET": {
		"zh": "确认重置",
		"en": "Confirm",
	},
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
	"WIN_TITLE": {
		"zh": "%s  获胜！",
		"en": "%s  wins!",
	},
	"WIN_SUBTITLE": {
		"zh": "率先抵达水面 · %d / %d",
		"en": "First to the surface · %d / %d",
	},
	"WIN_STATS": {
		"zh": "累计胜场 %d ｜ 已完成对局 %d",
		"en": "Total wins %d  |  Matches %d",
	},
	"RESET_TITLE": {
		"zh": "重置存档与配置",
		"en": "Reset Save & Settings",
	},
	"RESET_BODY": {
		"zh": "将清空玩家名称、分数、胜场等全部存档数据，\n并把各项配置恢复默认（音效开启、静音关闭、语言英文）。\n此操作不可撤销。",
		"en": "This clears all saved data (names, scores, wins)\nand restores default settings (sound on, mute off, language English).\nThis cannot be undone.",
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
