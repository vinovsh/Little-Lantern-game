# Little Lantern

An illustrated Android puzzle adventure built with **Godot 4.5.1**, GDScript and the Compatibility renderer. No account or developer backend is required.

## Play

Guide a lantern carrying creature through **40 authored puzzle adventure levels** in four chapters: forest (1–10), water (11–20), fire (21–30), and ice/wind (31–40). Each chapter introduces traversal rules, enemies, puzzles and a three-phase guardian.

- Left drag thumbstick, right jump and contextual USE button, with simultaneous touch support.
- Keys, locked doors, mirrors, receivers, pressure plates, movable crates, valves, decoys and recoverable traps.
- Swimming, floating cargo, rafts, lava, extinguishable heat decoys, temporary ice, wind and gliding.
- Twelve ordinary enemy families and four guardians with telegraphed attacks.
- Animated character, particles, original regional backgrounds and ambient music.
- Local checkpoint saves, free retries, gradual hints, puzzle journal, optional memories and chapter selection.
- Focus loss pauses gameplay; music, effects, vibration and reduced effects settings are available.

Keyboard: **A/D or arrows** move; **Space/W/Up** jump/swim/glide; **E/L** lantern; **F** interact; **J** journal; **Esc/P** pause.

Existing classic saves retain settings and forest access. Classic scores are archived; new campaign ratings and checkpoint state start afresh. Water opens after completing the rebuilt forest finale.

## Run locally

Install the exact standard Godot **4.5.1 stable** editor and matching export templates. Import `project.godot`, then run the main scene. No npm, database, API key or backend setup is needed.

```sh
godot --headless --editor --path . --import
godot --headless --fixed-fps 60 --path . tests/test_runner.tscn
godot --headless --fixed-fps 60 --path . tests/navigation.tscn
godot --headless --fixed-fps 60 --path . tests/traversal.tscn
godot --path .
```

Run `GODOT_BIN=/path/to/godot bash scripts/verify.sh` for the complete isolated test suite. It checks controls, saves, navigation and all 40 level mechanisms. Mechanism scenarios deliberately position the character at puzzle fixtures and exercise actual interaction, light, crate and enemy logic; they are not autonomous full-route walkthroughs. See `docs/CAMPAIGN_IMPLEMENTATION.md` for validation scope.

Rebuild authored campaign data with `python3 scripts/build_campaign.py`; regenerate original regional audio with `python3 scripts/build_audio.py`.

## Android export

Prerequisites: JDK 17, Android SDK platform 35, build tools 35.0.0, platform tools, NDK 28.1.13356709, Godot 4.5.1 and matching export templates. The generated Android build uses Gradle 8.13 and Android Gradle Plugin 8.6.1. Configure the Java SDK and Android SDK paths in Godot Editor Settings.

```sh
python3 scripts/prepare_android.py --template /path/to/4.5.1.stable/android_source.zip
mkdir -p build
godot --headless --path . --export-debug Android build/Little-Lantern-2.0.0.apk
```

The preset includes arm64-v8a, armeabi-v7a and x86_64, Android 8 or later, landscape orientation, immersive mode and disabled platform backup. `android/build` is generated and excluded from Git; `prepare_android.py` recreates the native integration deterministically. Build dependencies are downloaded by Gradle on first export.

The debug APK is for installation and testing. A Play release needs the publisher's signing setup, a release export, an incremented version code and a signed AAB. Signing credentials must remain outside version control. Remove x86_64 from a store build if emulator support is unnecessary.

The 2.0.0 build has desktop engine and exported-resource verification. Installation, touch comfort and sustained performance on a physical Android device remain to be checked. Earlier Android rendering checks do not establish device validation for this expanded campaign.

## Advertising

The native `LanternAds` bridge uses Google Mobile Ads **25.5.0** and UMP **4.0.0**. It implements consent gating, privacy options, rewarded callbacks, interstitials, bounded retries, expiry checks and foreground recovery. No mediation adapters or server-side rewards are included.

**Ads are disabled in the default configuration.** Gameplay never waits for an ad. No simulated ad grants exist in the player build. Unavailable rewarded revives are hidden; free retries remain available, and hints are free when no ad is available.

Copy `native/android/ads-config.example.json` to the ignored `native/android/ads-config.json`. Enable test ads only when validating the native integration. The example contains Google's test identifiers. Replace all three identifiers with the publisher's reviewed configuration before requesting live ads, and prepare the build with:

```sh
python3 scripts/prepare_android.py --template /path/to/android_source.zip --ads-config native/android/ads-config.json
```

Interstitial eligibility is every third completed level, after the first three session minutes and at least 120 seconds after the previous full screen ad. Ads appear only at a results transition. Live ad delivery, revenue, consent forms and store disclosures require publisher setup and device verification before release.

## Source map

| Location | Purpose |
| --- | --- |
| `scripts/game.gd` | Screens, menus, HUD, touch controls and app lifecycle |
| `scripts/world.gd` | Level objects, puzzles, checkpoints, particles and completion |
| `scripts/hero.gd` | Character physics and animation |
| `scripts/drag_control.gd` | Left thumbstick, proportional movement and touch ownership |
| `scripts/level_data.gd` | 40 authored layouts and validation |
| `scripts/save_service.gd` | Versioned local save, backup and recovery |
| `scripts/audio_service.gd` | Music and sound effects |
| `scripts/ad_service.gd` | Engine-facing advertising lifecycle |
| `native/android/LanternAds.java` | Optional Android advertising bridge |
| `tests/` | Control, navigation and mechanism scenario tests |
| `docs/` | Specification, art provenance and validation records |

Local saves live under Godot's `user://` directory. Uninstalling or clearing app data removes progress. This version has no cloud restoration or cross-device synchronization.

## Artwork and third party notices

The art was generated specifically for this game and normalized into game assets. The storyboard is a visual reference; the running game has its own reusable assets and animations. Ambient music and effects are original procedural audio. See `docs/ARTWORK.md`, `assets/licenses/GODOT.txt` and `assets/fonts/LICENSE.txt` for provenance and notices. No project-wide source licence has been selected.
