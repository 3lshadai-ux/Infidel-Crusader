# Ambient music (original)

Soft Christian-elevator / muzak-style loops for free roam. **Original audio only** — no copyrighted hymns.

## How it plays (no setup needed)

`AudioManager` (autoload) starts on boot:

1. Tries `ambient_bed.ogg` / `ambient_swell.ogg` if present (Godot-imported).
2. Else loads `*.ogg.b64` companions via `AudioStreamOggVorbis.load_from_buffer`.
3. Else synthesizes a soft **I–IV–V–I** pad with `AudioStreamGenerator` (always works).

As you approach an active miracle marker, intensity **builds** (volume + swell + slight pitch lift). During KJV scripture TTS, music **ducks** so quotes stay clear.

## Bundled / generated files

| File | Role |
|------|------|
| `ambient_bed.ogg` / `.ogg.b64` | Soft looping pad (~6–32s) |
| `ambient_swell.ogg` / `.ogg.b64` | Higher shimmer stem near miracles |

```bash
python3 tools/generate_ambient_music.py   # needs ffmpeg for OGG + b64
```

## Replace with your own tracks

1. Drop seamless loops as `ambient_bed.ogg` and `ambient_swell.ogg`.
2. Re-open in Godot so they import.
3. Keep loops short (20–60s) for mobile.
