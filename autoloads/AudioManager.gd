extends Node

var sounds: Dictionary = {
    "coin":     {"freq": 880.0, "dur": 0.12, "vol": 0.6},
    "knife":    {"freq": 200.0, "dur": 0.18, "vol": 0.9},
    "gunshot":  {"freq": 150.0, "dur": 0.22, "vol": 1.0},
    "death":    {"freq": 120.0, "dur": 0.4,  "vol": 0.8},
    "pickup":   {"freq": 660.0, "dur": 0.15, "vol": 0.7},
    "win":      {"freq": 523.0, "dur": 0.8,  "vol": 0.8},
    "lose":     {"freq": 180.0, "dur": 0.8,  "vol": 0.8},
    "footstep": {"freq": 300.0, "dur": 0.08, "vol": 0.3},
    "vote":     {"freq": 440.0, "dur": 0.1,  "vol": 0.5},
    "join":     {"freq": 600.0, "dur": 0.2,  "vol": 0.6},
}

func play(sound_name: String) -> void:
    if not sounds.has(sound_name):
        return
    var s: Dictionary = sounds[sound_name]
    _play_beep(s["freq"], s["dur"], s["vol"])

func _play_beep(freq: float, dur: float, vol: float) -> void:
    var ap := AudioStreamPlayer.new()
    add_child(ap)
    var gen := AudioStreamGenerator.new()
    gen.mix_rate = 22050.0
    gen.buffer_length = dur + 0.05
    ap.stream = gen
    ap.volume_db = linear_to_db(vol)
    ap.play()
    var pb := ap.get_stream_playback() as AudioStreamGeneratorPlayback
    if pb == null:
        ap.queue_free()
        return
    var frames: int = int(22050.0 * dur)
    var fade_frames: int = int(22050.0 * 0.02)
    for i in range(frames):
        var t: float = float(i) / 22050.0
        var env: float = 1.0
        if i < fade_frames:
            env = float(i) / float(fade_frames)
        elif i > frames - fade_frames:
            env = float(frames - i) / float(fade_frames)
        var v: float = env * sin(TAU * freq * t)
        pb.push_frame(Vector2(v, v))
    get_tree().create_timer(dur + 0.1).timeout.connect(ap.queue_free)
