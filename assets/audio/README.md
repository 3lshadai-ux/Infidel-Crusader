# Ambient music (original)

Soft Christian-elevator / muzak-style loops for free roam. **Original audio only** — no copyrighted hymns.

| File | Role |
|------|------|
| `ambient_bed.ogg` | Soft looping pad (I–IV–V–I in C major), ~32s |
| `ambient_swell.ogg` | Higher shimmer stem that fades in near miracles |
| `*.ogg.b64` | Base64 companions (loaded if `.ogg` is missing from the import pipeline) |

## How it plays

`AudioManager` (autoload) starts the bed on boot. As you approach an active miracle marker, intensity rises (volume + swell layer + slight pitch lift). During KJV scripture TTS, the bed ducks so the quote stays clear.

## Replace with your own tracks

1. Drop your own seamless loops as:
   - `assets/audio/ambient_bed.ogg`
   - `assets/audio/ambient_swell.ogg`
2. Re-open the project in Godot so they import.
3. Keep loops short (20–60s) and modest bitrate for mobile.

## Regenerate the bundled originals

```bash
python3 tools/generate_ambient_music.py
# needs ffmpeg on PATH for OGG output
```
