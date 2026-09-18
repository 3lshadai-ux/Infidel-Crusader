# Android export — Infidel Crusader

## Prerequisites

1. Godot **4.3+** with **Android Build Template** installed
   Editor → Editor → Manage Export Templates → download matching version.
2. Android SDK / NDK / JDK as required by Godot's Android export docs.
3. A debug keystore (Godot can generate one in Project → Export → Android).

## Steps

1. Open this project in Godot.
2. Project → Export → Add → **Android**.
3. Load or edit `export_presets.cfg` (stub included). Set:
   - Package/unique name (e.g. `com.elshadai.infidelcrusader`)
   - App name: **Infidel Crusader**
   - Architectures: arm64-v8a (required for modern devices)
4. Export Project → `.apk` or `.aab`.
5. Install on device; grant nothing special for the MVP (no network required).

## TTS on Android

Miracle completion calls `DisplayServer.tts_speak` with the KJV quote.
On-screen scripture always appears. Device TTS voices vary by OEM/language pack; install a quality English voice for best results. Future builds may ship recorded narration.

## Orientation

Project prefers **landscape** (`window/handheld/orientation` landscape) for open-world feel.
