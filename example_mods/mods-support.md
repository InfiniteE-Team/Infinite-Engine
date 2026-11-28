# Modding Guide — Friday Night Funkin': Infinite Engine
> Engine version: **0.1.0-pre** · API version: **0.1.0**

---

## Folder structure

All mods live inside the `mods/` folder at the root of the game.

> **Any animated element can be an atlas or an XML file, this is detected automatically.**

```
mods/
└── your-mod-name/
    ├── meta.json              ← required
    ├── game/
    │   ├── songs/
    │   │   └── my-song/
    │   │       ├── meta.json
    │   │       ├── events.json
    │   │       ├── charts/
    │   │       │   └── normal.json
    │   │       └── audio/
    │   │           ├── Inst.ogg
    │   │           └── Voices.ogg
    │   ├── characters/
    │   │    └── character/...
    │   │       ├── character.json
    │   │       ├── image.png
    │   │       ├── image.xml
    │   │       ├── script <- optional HxScript / Lua scripts
    │   │       └── icon.png
    │   ├── stages/
    │   ├── images/
    │   └── scripts here too <- optional HxScript / Lua scripts
    ├── general/
    │   ├── shaders/
    │   ├── cursor/ <- Custom Cursor
    │   │   ├── cursor.json
    │   │   └── cursorCustom.png
    │   └── fonts/...
    └── menus/
        ├── freeplay/
        │   └── albums/
        ├── mainmenu/...
        ├── options/...
        │   └── options.json <- custom options
        ├── title/...
        ├── stickers/...
        │    └── skin-custom
        │           ├── sticker1.png
        │           ├── sticker2.png ....
        │           └── skin-custom.json
        ├── credits/
        │    └── credits.json <- custom credits
        ├── loading/
        │    └── characters/
        │           └── customCharacter/...
        │               ├── customCharacter.json
        │               ├── customCharacter.png
        │               └── customCharacter.xml
        └── storymenu/
            ├── chars/
            │       ├── customcharacter.png
            │       ├── customCharacter.xml
            │       └── customCharacter.json
            ├── difficulties/
            │       └── customDifficulty.png
            ├── ui/...
            └── weeks/
                    ├── weekCustom.png
                    └── weekCustom.json


```

The engine merges your mod folder on top of the base assets automatically when your mod is selected.

---

## meta.json

Every mod must have a `meta.json` in its root folder.

```json
{
  "name": "your-mod-name",
  "title": "Your Mod Title",
  "author": "YourName",
  "description": "A short description of your mod.",
  "mod_version": "1.0.0",
  "api_version": "0.1.0"
}
```

| Field | Required | Description |
|---|---|---|
| `name` | ✓ | Internal ID, matches the folder name |
| `title` | ✓ | Display name shown in the mods menu |
| `author` | — | Your name or team name |
| `description` | — | Short description shown in the mods menu |
| `mod_version` | — | Your mod's version |
| `api_version` | — | Engine API version this mod targets (`0.1.0`) |
| `appIcon` | — | Path to a `.png` to use as the window icon |
| `discord` | — | Discord RPC |
| `webPage` | — | Website link |


### Starting mod

If you set `"startingMod": true` in your `meta.json`, the engine will activate your mod by default the first time the player launches the game (before they've chosen any mod manually).

```json
{
  "name": "your-mod-name",
  "title": "Your Mod",
  "startingMod": true
}
```

Only one mod can be the starting mod. If more than one has it set, the engine picks the first one it finds.

---

## Global config (`general/global.json`)

You can place a `general/global.json` file inside your mod to override engine-level settings. This lets you, for example, change the state the game boots into.

```
mods/your-mod-name/
└── general/
    └── global.json
```

```json
{
  "startState": "MyCustomTitleState",
  "noteSkin": "my-noteskin",
  "ui": "my-ui",
  "skipTrans": false,
  "developerMode": false
}
```

| Field | Default | Description |
|---|---|---|
| `startState` | `"TitleState"` | Class name of the state to boot into |
| `noteSkin` | `"default"` | Note skin ID to use |
| `ui` | `"default"` | UI skin ID to use |
| `skipTrans` | `false` | Skip screen transitions |
| `developerMode` | `true` | Enables debug/dev features |

> **V-Slice / Polymod mods:** if your mod uses `_polymod_meta.json` instead of `meta.json`, the engine will detect and load it automatically.

---

## Scripting

The engine supports two scripting languages: **HxScript** (`.hx`) and **Lua** (`.lua`).

Scripts are loaded from your mod's `game/` folder (or whichever folder the game looks up for a given context, e.g. `game/stages/stageCustom/`, `songs/song/scripts/`, `source/states/`, `source/substates/`).

### HxScript example

```hx
// game/my-script.hx

var mySprite = new FlxSprite(100, 100);
mySprite.makeGraphic(50, 50, 0xFFFF0000);
add(mySprite);
```

### Lua example

```lua
-- game/my-script.lua

local spr = FlxSprite.new(100, 100)
spr:makeGraphic(50, 50, 0xFFFF0000)
add(spr)
```

Both languages share the same set of globals — whatever is listed below works in either.

---

## Available globals

These classes and objects are available in every script without any import.

### Flixel

| Name | Description |
|---|---|
| `FlxG` | Main Flixel entry point (camera, sound, state, etc.) |
| `FlxSprite` | Base sprite class |
| `FlxText` | Text object |
| `FlxSound` | Sound instance |
| `FlxTween` | Tweening utility |
| `FlxTimer` | Timer utility |
| `FlxEase` | Easing functions for tweens |
| `FlxMath` | Math helpers |

### Engine — game

| Name | Description |
|---|---|
| `PlayState` | The main gameplay state |
| `Character` | Character sprite class |
| `Stage` | Stage class |
| `Bar` | The health bar object |
| `Camera` | Engine camera class |
| `Alphabet` | The menu alphabet text sprite |
| `RhythmCore` | Beat/step timing core |
| `MusicBeatState` | Base class for all states |

### Engine — assets & audio

| Name | Description |
|---|---|
| `Paths` | Asset path resolver |
| `FunkinSprite` | Extended sprite with atlas/Sparrow support |
| `Sound` | Low-level sound loader |
| `SoundFX` | Sound effects helper |
| `MasterAudio` | Master volume/audio control |
| `GameAudio` | In-game music/vocals player |
| `AudioAnalyzer` | Frequency/beat analysis |

### Engine — scripting

| Name | Description |
|---|---|
| `ScriptHandler` | Access to the script system itself |
| `ScriptState` | Base class for a fully scripted state |
| `ScriptSubstate` | Base class for a fully scripted substate |
| `ScriptClass` | Utility to load and switch to scripted states |

### Engine — data & system

| Name | Description |
|---|---|
| `Json` | `haxe.Json` — parse/stringify JSON |
| `FormatJson` | Engine JSON helper (reads files directly) |
| `SaveData` | Player save data |
| `SaveScore` | Score saving utility |
| `globalConfig` | Global engine config object |
| `modData` | Current mod's metadata (`meta.json` contents) |
| `Controls` | Input/controls helper |
| `FileSystem` | `sys.FileSystem` — check/list files |
| `File` | `sys.io.File` — read/write files |
| `Capabilities` | OpenFL system capabilities |

### Engine — rendering & video

| Name | Description |
|---|---|
| `CustomShader` | GLSL shader wrapper |
| `VideoSprite` | In-game video sprite |
| `VideoState` | Fullscreen video cutscene state |

### Modchart

| Name | Description |
|---|---|
| `ModchartSystem` | Modchart controller |
| `DrunkModifier` | Wavy note lane modifier |
| `TornadoModifier` | Tornado spin modifier |
| `TipsyModifier` | Tipsy X modifier |
| `TipsyZModifier` | Tipsy Z modifier |
| `ReverseModifier` | Flips scroll direction |
| `FlipModifier` | Flips the lane horizontally |
| `ConfusionModifier` | Rotates note angles |
| `MiniModifier` | Shrinks notes |
| `StealthModifier` | Makes notes invisible |
| `ZModifier` | Z-depth modifier |
| `SpeedModifier` | Note scroll speed modifier |
| `ConfusionOffsetModifier` | Offset-based confusion |
| `TwirlModifier` | Twirl modifier |
| `ShakyModifier` | Shake modifier |
| `PulseModifier` | Pulse scale modifier |
| `BlinkModifier` | Blink visibility modifier |
| `TanDrunkModifier` | Tangent-based drunk modifier |
| `BeatXModifier` | Beat-synced X movement |
| `ShrinkXModifier` | X-axis shrink modifier |

### 3D — Foxlite

| Name | Description |
|---|---|
| `FoxScene` | 3D scene |
| `FoxObject` | 3D object |
| `FoxModel` | 3D model |
| `FoxCamera` | 3D camera |
| `FoxShader` | 3D shader |
| `FoxCache` | Asset cache for 3D |
| `FoxBasic` | Base 3D class |
| `FoxOfflineScene` | Offline/static 3D scene |
| `FoxInstancedModel` | Instanced 3D model |

---

## V-Slice compatibility

If your mod is a V-Slice (Polymod) mod — i.e. it ships a `_polymod_meta.json` — the engine will automatically enable V-Slice compatibility mode.

In this mode, the engine supports **JSON Patch** (`_merge`). You can place patch files under `_merge/` to modify base game JSON files without fully replacing them:

```
mods/your-mod-name/
└── _merge/
    └── game/characters/bf.json   ← patches bf.json from the base game
```

Supported patch operations: `add`, `replace`, `remove` (standard JSON Patch / RFC 6902 format).

---

## Tips

- Use `trace()` or `Console.log()` to print debug messages to the console.
- Scripts that fail to parse or crash at runtime are skipped — the rest of the game keeps running.
- You can read and write files from scripts using `FileSystem` and `File`, but keep paths relative to the game folder.
- `Paths.getPath(name, type)` resolves asset paths through the mod system automatically.