# Android export - Infidel Crusader

## Prerequisites

1. Godot **4.3+** with **Android Build Template** installed  
   Editor -> Manage Export Templates -> download matching version.
2. Android SDK / NDK / JDK as required by Godot's Android export docs.
3. A debug keystore (Godot can generate one in Project -> Export -> Android).

## Project settings already tuned for phones

In `project.godot`:

- `config/features` includes **Mobile**
- `renderer/rendering_method` = **mobile**
- `textures/vram_compression/import_etc2_astc` = true (ASTC/ETC2)
- Window stretch: `canvas_items` + `expand` (UI scales on tall/wide phones)
- `window/handheld/orientation` = landscape (value `4`)
- Viewport base: 1280x720 - scales up/down via stretch

In `export_presets.cfg` (stub):

- Package: `com.elshadai.infidelcrusader`
- Architecture: **arm64-v8a** only (modern devices)
- Immersive mode: on
- Screen size support: small -> xlarge
- Version name mirrors `config/version` (bump both when shipping)

## Steps

1. Open this project in Godot 4.3+.
2. Project -> Export -> select **Android** (or Add -> Android if missing).
3. Confirm `export_presets.cfg` values; set your debug/release keystore paths in the editor (do **not** commit keystores).
4. Export Project -> `.apk` (debug) or `.aab` (Play Store).
5. Install on device. MVP needs no special runtime permissions (no network).

### Gradle / one-click install (optional)

For editor one-click deploy, enable **Gradle Build** in the Android preset and install the Android SDK path under Editor Settings -> Export -> Android. The stub keeps `gradle_build/use_gradle_build=false` so a plain APK export works with templates alone.

## Touch controls / UI anchors

- **Virtual joystick** - bottom-left (`scenes/ui/virtual_joystick.tscn`); drag works with mouse on desktop too.
- **Interact** + **Journal** - bottom-right large buttons (56px min height) for thumbs.
- **Mission / scripture / puzzle** panels - centered with autowrap; scripture panel widened for readable KJV on phones.
- **Clue panel** - top-right so it does not cover the stick.
- Prefer landscape; portrait is not the design target.

If UI feels cramped on small phones, increase Display -> Window -> stretch scale in the editor or enlarge BottomBar button `custom_minimum_size`.

## TTS on Android

Miracle completion calls `DisplayServer.tts_speak` with the KJV quote. On-screen scripture always appears. Device TTS voices vary by OEM/language pack - install a quality English voice for best results. Future builds may ship recorded narration.

## Smoke test on device

1. Move with the left stick; open Journal; confirm TopBar readable.
2. Complete Follow Me; confirm level-up + scripture overlay readable.
3. Walk to Cana; reveal clues; solve riddle **or** fill jars via Interact.
4. Confirm no UI element blocks the stick permanently.

## Orientation

Project prefers **landscape** for open-world feel. Keep phone landscape lock on when playtesting.
