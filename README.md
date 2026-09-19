# Infidel Crusader

**Genre:** GTA-like open-world action sandbox for mobile  
**Engine:** Godot **4.7+** (Android export target)  
**Status:** Level 1 playable pass — ambient music + cinematic miracle set-pieces (**v0.2.2**)

A stylized, fictional New Testament-era coastal open world. You begin as a **fishmonger** at the market/docks. The opening calling: encounter Jesus, **follow Him**, and become a **Disciple**. Then travel the map for miracles and major story beats.

Tone: respectful of the Gospels inside a sandbox game frame. Title is edgy; content and code stay professional. Fiction/sandbox - no real-world targeting or calls to real violence.

---

## Restore note (v0.2.2)

`scripts/audio_manager.gd` on `main` was briefly overwritten with the literal text `PLACEHOLDER` (commit `14738c1`). It was restored to the full Godot **4.7-safe** ambient script (no `Class.has_method` on native classes; uses `AudioStreamOggVorbis.load_from_buffer`). If your local clone still shows an 11-byte file, run `git pull`.

Also: `miracle_encounter_core.gd` briefly hit a placeholder during the 4.7 pass and was restored with Godot 4.7 method stubs so subclass overrides type-check cleanly.

---

## What is playable now (desktop F5 / Android)

| Feature | Status |
|--------|--------|
| 3D ancient-Israel blockout (roads, pads, signposts) | **Playable** |
| Third-person controller + virtual joystick | **Playable** |
| **Follow Me** - stay near Jesus on the shore path | **Playable** |
| **Water to Wine (Cana)** - multi-clue -> puzzle -> miracle | **Playable (showcase)** |
| Nets Overflow / Calm the Storm / Loaves and Fish | **Playable** (clue + riddle + witness) |
| * Transfiguration (Tabor climb + light) | **Playable** set-piece |
| * Gethsemane (keep-watch timer) | **Playable** set-piece |
| * Crucifixion (Golgotha climax) | **Playable** set-piece |
| Journal / clue panel / puzzle dialog / level-up toast | **Yes** |
| KJV overlay + `DisplayServer.tts_speak` | **Yes** |
| Vehicles / wanted / huge GIS map / multiplayer | Roadmap only |


### Music (Christian elevator bed)

Soft original **hymn-adjacent elevator/muzak** loops play during free roam (`AudioManager` autoload).

| How to hear it | What happens |
|----------------|--------------|
| Start the game (F5) | Gentle looping ambient bed (I–IV–V–I pad) |
| Walk toward an **active** miracle / major-beat marker | Intensity **builds** — louder bed, swell stem, slight pitch lift |
| Witness / scripture overlay + TTS | Music **peaks**, then **ducks** so KJV quotes stay clear |
| Leave the marker / finish the beat | Ease back to soft roam bed |

Original audio only (no copyrighted hymns). Files under `assets/audio/` — see that folder’s README to swap custom OGG loops. Generator: `tools/generate_ambient_music.py`.

### Deepened set-pieces

| Beat | What you’ll notice |
|------|--------------------|
| **Water to Wine** | Wedding lanterns, guest markers, jar water→wine color change |
| **Nets Overflow** | Boat/dock + net grid; haul-net participate before scripture |
| **Calm the Storm** | Sky darkens + wind streaks; calm light when you witness |
| **Loaves and Fish** | Crowd ring + basket; multiply food particles |
| **★ Transfiguration** | Bright cloud/bloom hold; “voice out of the cloud” framing |
| **★ Gethsemane** | Night lighting, olive trees; sleep-warning if you leave the watch |
| **★ Crucifixion** | Approach path, solemn light, cross silhouette; Level 1 complete banner |

### Water to Wine showcase (first post-disciple miracle)

1. Finish **Follow Me** -> unlocks Cana.
2. Follow signposts inland to the **Cana** marker (purple-tinted pillar / blue encounter beacon).
3. Approach to reveal **multi-step clues** in the clue panel + journal.
4. **Puzzle gate:** answer the waterpots riddle (**6**) *or* walk to each of the six jars and press **E / Interact** to fill them.
5. Enter **miracle** phase -> Interact to participate/observe.
6. **KJV overlay + TTS**, level-up toast, next miracle unlocks.

### Progression

- Start: **Fishmonger**, Level **0**, Miracles **0/8**
- Each completed entry: `player_level += 1`, cash reward, status title, next unlock
- Miracle states: `locked -> clues -> puzzle -> miracle -> done`
- `GameState` remains the source of truth (`clues`, `puzzle`, `state`)

### Level 1 story arc (ordered)

1. **Follow Me** - fishmonger -> disciple (**playable**)
2. **Water to Wine** - Cana showcase (**playable**, full clue->puzzle->miracle)
3. Nets Overflow (**playable** loop)
4. Calm the Storm (**playable** loop)
5. Loaves and Fish (**playable** loop)
6. * **The Transfiguration** (**playable** set-piece)
7. * **Garden of Gethsemane** (**playable** keep-watch)
8. * **The Crucifixion** - Level 1 climax (**playable**)

### World map - stylized ancient Israel

Readable travel fantasy (not GIS-accurate): clearer roads **Galilee -> Cana -> Nazareth -> Tabor -> south** (Samaria / Bethany / Jerusalem / Olives / Golgotha), city plazas, wooden signposts.

| Location | Blockout | Campaign |
|----------|----------|----------|
| Sea of Galilee / Capernaum | Spawn, docks, stalls | Follow Me; Calm the Storm |
| Bethsaida | Pad + path | Nets Overflow; Loaves and Fish |
| Cana | Pad + inland road + signposts | Water to Wine |
| Nazareth area | Pad | Regional flavor |
| Mount of Transfiguration | Rise + major marker | * Transfiguration |
| Samaria / Bethany / Jerusalem | Roads + pads | Travel south |
| Mount of Olives / Gethsemane | Emissive marker | * Gethsemane |
| Golgotha | Emissive marker | * Crucifixion |

Scripture strings are **public-domain KJV** only.

---

## How to open & run (Godot 4.7)

1. Install [Godot **4.7+**](https://godotengine.org/download) (Standard), or the [4.7-stable](https://github.com/godotengine/godot/releases/tag/4.7-stable) release.
2. **`git pull`** the latest `main` (required after the audio_manager restore).
3. If you previously opened the project in an older Godot: **delete the `.godot/` folder**, then Import → select `project.godot` so assets reimport cleanly.
4. Press **F5**. Main scene: `scenes/main.tscn`.
5. **Controls:** WASD / arrows; on-screen stick; **E** / Interact; **J** / Journal (`journal` input action).

Opening tip: start near the shore, walk toward **Jesus**, stay close on the **Follow Me** path until you become a Disciple.

### Key files

```
scripts/game_state.gd          # campaign, clues, puzzles, states, KJV/TTS
scripts/audio_manager.gd       # ambient bed + intensity ramp + TTS duck (4.7-safe)
scripts/miracle_encounter.gd   # interaction layer (extends MiracleEncounterCore)
scripts/miracle_encounter_core.gd  # stages, lighting, ambience hooks + 4.7 stubs
scripts/miracle_setpieces.gd   # cinematic stage/FX helpers (class_name)
scripts/city_blockout.gd       # roads, pads, signposts
scripts/map_markers.gd         # labeled places
scripts/hud.gd / scenes/ui/hud.tscn
assets/audio/                  # original OGG loops (+ .b64 companions)
tools/generate_ambient_music.py
scenes/miracle_encounter.tscn
scenes/main.tscn
docs/ANDROID_EXPORT.md
```

---

## Android export

See [docs/ANDROID_EXPORT.md](docs/ANDROID_EXPORT.md). Stub `export_presets.cfg` included - install Android templates and a debug keystore before exporting.

---

## Roadmap

- Recorded narration / richer NPC crowds
- Level 2: Resurrection onward
- Vehicles + wanted/heat
- Larger hand-authored map, NPCs, economy

---

## License notes

- Game code/assets: project ownership.
- **KJV** Bible text is public domain.
