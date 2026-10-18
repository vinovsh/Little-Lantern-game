extends Node
var music: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var cursor := 0
var silent_runner := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	silent_runner = DisplayServer.get_name() == "headless"
	music = AudioStreamPlayer.new()
	add_child(music)
	music.stream = preload("res://assets/audio/forest.wav")
	(music.stream as AudioStreamWAV).loop_begin = 0
	(music.stream as AudioStreamWAV).loop_end = int(round(music.stream.get_length() * (music.stream as AudioStreamWAV).mix_rate))
	(music.stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.volume_db = linear_to_db(maxf(0.0001, float(Save.data.settings.music))) - 8
	if not silent_runner:
		music.play()
	for i in range(8):
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func cue(name: String, pitch := 1.0) -> void:
	if silent_runner:
		return
	var path := "res://assets/audio/%s.wav" % name
	if not ResourceLoader.exists(path):
		return
	var voice: AudioStreamPlayer = voices[cursor % voices.size()]
	cursor += 1
	voice.stream = load(path)
	voice.pitch_scale = pitch
	voice.volume_db = linear_to_db(maxf(0.0001, float(Save.data.settings.effects))) - 8
	voice.play()

func refresh() -> void:
	music.volume_db = linear_to_db(maxf(0.0001, float(Save.data.settings.music))) - 8

func suspend(value: bool) -> void:
	music.stream_paused = value
	for voice in voices:
		voice.stream_paused = value

func shutdown() -> void:
	if music != null:
		music.stop()
		music.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null

func _exit_tree() -> void:
	shutdown()


func play_theme(chapter: int) -> void:
	if silent_runner:return
	var path = "res://assets/audio/"+["forest","river","ember","sky"][clampi(chapter,0,3)]+".wav"
	var stream = load(path) as AudioStreamWAV
	if music.stream==stream:return
	music.stop()
	music.stream=stream
	stream.loop_begin=0
	stream.loop_end=int(round(stream.get_length()*stream.mix_rate))
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	music.play()
