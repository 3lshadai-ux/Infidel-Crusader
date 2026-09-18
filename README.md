# Infidel Crusader

**Genre:** GTA-like open-world action sandbox for mobile  
**Engine:** Godot 4.3+ (Android export target)  
**Status:** Playable slice MVP — not a full GTA clone

A stylized, fictional New Testament–era coastal open world. You begin as a **fishmonger** at the market/docks. The opening calling: encounter Jesus, **follow Him**, and become a **Disciple**. Later miracles and major story beats advance Level 1 campaign progress.

Tone: respectful of the Gospels’ calling-of-disciples narrative inside a sandbox game frame. Title is edgy; content and code stay professional. Fiction/sandbox — no real-world targeting or calls to real violence.

---

## What this MVP includes

| Feature | In MVP? |
|--------|---------|
| 3D coastal city blockout (market, dusty streets, docks, water) | Yes |
| Third-person on-foot controller + camera follow | Yes |
| Virtual joystick (touch) + WASD (desktop) | Yes |
| Opening mission: follow Jesus → Disciple | Yes (playable) |
| Cash HUD + status + mission clue | Yes |
| **Leveling:** `player_level` = miracles/beats completed | Yes |
| Miracle campaign data + clues unlock chain | Yes (data + first beat playable) |
| KJV scripture overlay + `DisplayServer.tts_speak` | Yes |
| **Major beats:** Transfiguration, Gethsemane, Crucifixion | Data + UI flags (set-piece gameplay stubbed) |
| Vehicles / wanted system / huge map / multiplayer | Roadmap only |

### Progression scheme

- Start: **Fishmonger**, Level **0**, Miracles **0/N**
- Each completed miracle/beat: `player_level += 1`, level-up toast, unlock next clue, KJV read-aloud
- Titles update at milestones (Disciple → Witness → Apostle → Witness of the Cross)

### Level 1 story arc (ordered)

1. **Follow Me** — fishmonger → disciple (playable)
2. Nets Overflow
3. Water to Wine
4. Calm the Storm
5. Loaves and Fish
6. ★ **The Transfiguration** — major mid/late beat
7. ★ **Garden of Gethsemane** — major beat before the end
8. ★ **The Crucifixion** — Level 1 climax / ending

### World map — stylized ancient Israel

Open-world blockout is **not** GIS-accurate; it is a readable NT-era travel fantasy with labeled places.

| Location | v0 blockout | Campaign ties |
|----------|-------------|---------------|
| Sea of Galilee (shore) / Capernaum market | Yes (spawn, docks, stalls) | Follow Me; Calm the Storm |
| Bethsaida | Yes (marker + path) | Nets Overflow; Loaves and Fish |
| Cana | Yes (marker + inland path) | Water to Wine |
| Nazareth area | Yes (marker) | Regional flavor |
| Mount of Transfiguration | Yes (rise + major marker) | ★ Transfiguration |
| Road through Samaria | Stub marker | Travel south |
| Bethany | Stub marker | Later detail |
| Jerusalem | Stub marker | Approach to climax |
| Mount of Olives / Gethsemane | Stub marker (emissive) | ★ Gethsemane |
| Golgotha | Stub marker (emissive) | ★ Crucifixion (Level 1 end) |

Each miracle/beat in `GameState.miracles` has a `location_id` pointing at `GameState.map_locations`. `MapMarkers` draws Label3D pads; clues unlock the next region.

Major beats use `is_major_beat = true` in `GameState.miracles`, a distinct HUD banner, and journal starring (`MiracleJournal`). Full set-piece gameplay is stubbed; scripture + framing ship in MVP.

Scripture strings are **public-domain KJV** (accurate verse text, not paraphrased). On-screen text always shows; TTS uses Godot `DisplayServer.tts_speak` when the OS provides voices (Android TTS quality varies). Future: recorded narration assets.

---

## How to open & run (desktop)

1. Install [Godot 4.3+](https://godotengine.org/download) (Standard build is fine).
2. Open Godot → **Import** → select `project.godot` in this repo.
3. Press **F5** (or Play). Main scene: `scenes/main.tscn`.
4. **Controls:** WASD / arrows to move; on-screen stick also works with mouse drag. Walk to the yellow beacon (Jesus), stay close as He walks the shore path.

### Key scenes & scripts

```
project.godot
scenes/main.tscn          # coastal world + player + Jesus + HUD
scenes/player.tscn        # CharacterBody3D third-person
scenes/jesus_npc.tscn     # follow-path NPC + beacon
scenes/ui/hud.tscn        # cash, level, miracles, scripture, major-beat UI
scenes/ui/virtual_joystick.tscn
scripts/game_state.gd     # autoload: campaign, leveling, KJV, TTS
scripts/player.gd
scripts/jesus_npc.gd
scripts/city_blockout.gd  # procedural market/docks blockout
scripts/hud.gd
scripts/virtual_joystick.gd
scripts/journal.gd        # major-beat journal formatting
scripts/map_markers.gd    # ancient-Israel labeled places
```

---

## Android export

See [docs/ANDROID_EXPORT.md](docs/ANDROID_EXPORT.md). A stub `export_presets.cfg` is included — you must install Android build templates and set a debug keystore in the Godot editor before exporting.

---

## Roadmap (post-MVP)

- Implement stubbed miracle locations as real map objectives
- Full set-pieces for Transfiguration / Gethsemane / Crucifixion
- Level 2: Resurrection onward
- Simple vehicle + wanted/heat system
- Larger hand-authored map, NPCs, economy
- Recorded scripture narration packs
- Optional multiplayer (very late)

---

## License notes

- Game code/assets in this repo: see project ownership.
- **KJV** Bible text is public domain.
