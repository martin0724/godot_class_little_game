extends Node
## 音效管理器（自动加载单例：SoundManager）。
## 不依赖任何音频素材 —— 启动时用代码合成 AudioStreamWAV 波形，
## 再通过一组 AudioStreamPlayer 轮询播放，支持多个音效重叠。

const MIX_RATE := 44100
const POOL_SIZE := 12

var _players: Array[AudioStreamPlayer] = []
var _sounds: Dictionary = {}   # key -> AudioStreamWAV
var _volumes: Dictionary = {}  # key -> float (dB)
var _next := 0
var muted := false             ## 全局静音开关


func _ready() -> void:
	for i in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_players.append(player)

	# 按钮点击：短促高音“嗒”
	_add("click", _chirp(0.05, 1300.0, 760.0, 0.35, 0.001, 3.0), -9.0)
	# 加分上浮：向上滑音 + 气泡感
	_add("up", _chirp(0.18, 430.0, 1040.0, 0.5, 0.004, 1.7), -3.0)
	# 扣分下沉：向下滑音
	_add("down", _chirp(0.22, 640.0, 240.0, 0.5, 0.004, 1.5), -3.0)
	# 边界无效（已在顶端/底端）：低沉短音
	_add("denied", _chirp(0.12, 200.0, 150.0, 0.45, 0.002, 1.4), -7.0)
	# 获胜：四音上行小号
	_add("win", _fanfare(), -1.0)

	_load_settings()


func play(key: String) -> void:
	if muted or _players.is_empty() or not _sounds.has(key):
		return
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _sounds[key]
	player.volume_db = float(_volumes[key])
	player.play()


func play_click() -> void:
	play("click")


func play_up() -> void:
	play("up")


func play_down() -> void:
	play("down")


func play_denied() -> void:
	play("denied")


func play_win() -> void:
	play("win")


# ——————————————————— 全局静音 ———————————————————

func is_muted() -> bool:
	return muted


func set_muted(value: bool) -> void:
	if value == muted:
		return
	_apply_mute(value)
	DataStore.set_setting("muted", muted)


func _apply_mute(value: bool) -> void:
	muted = value
	var idx := AudioServer.get_bus_index("Master")
	if idx >= 0:
		AudioServer.set_bus_mute(idx, muted)


func _load_settings() -> void:
	_apply_mute(bool(DataStore.get_setting("muted", false)))


# ——————————————————— 波形合成 ———————————————————

func _add(key: String, samples: PackedFloat32Array, volume_db: float) -> void:
	_sounds[key] = _to_wav(samples)
	_volumes[key] = volume_db


## 生成一段频率从 f0 线性滑到 f1 的正弦波，带淡入与衰减包络。
func _chirp(duration: float, f0: float, f1: float, amp: float, attack: float = 0.006, decay_pow: float = 1.8) -> PackedFloat32Array:
	var n := int(duration * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	if n <= 0:
		return out
	var dt := 1.0 / float(MIX_RATE)
	var attack_n := maxf(1.0, attack * float(MIX_RATE))
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n - 1)
		var freq := lerpf(f0, f1, t)
		phase += TAU * freq * dt
		var env := pow(1.0 - t, decay_pow)
		var atk := minf(1.0, float(i) / attack_n)
		out[i] = sin(phase) * amp * env * atk
	return out


## 四音上行小号（C5 - E5 - G5 - C6）。
func _fanfare() -> PackedFloat32Array:
	var notes := PackedFloat32Array([523.25, 659.25, 783.99, 1046.50])
	var out := PackedFloat32Array()
	for i in notes.size():
		var is_last := i == notes.size() - 1
		var dur := 0.45 if is_last else 0.13
		var decay := 1.0 if is_last else 1.6
		out.append_array(_chirp(dur, notes[i], notes[i], 0.5, 0.005, decay))
	return out


## 把 -1..1 的浮点采样转成 16bit 单声道 PCM 的 AudioStreamWAV。
func _to_wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		var v := clampf(samples[i], -1.0, 1.0)
		data.encode_s16(i * 2, int(round(v * 32000.0)))
	wav.data = data
	return wav
