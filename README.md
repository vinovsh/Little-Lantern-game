# Little Lantern

An illustrated Android puzzle adventure built with **Godot 4.5.1**, GDScript and the Compatibility renderer. No account or developer backend is required.

## Play

Guide a small lantern carrying creature through ten handcrafted levels in moonlit forests, caverns and ancient ruins. Collect five fireflies, reveal hidden bridges, illuminate sun receivers and reach the gate. Later levels introduce lantern attracted moths and moving platforms.

- Landscape touch controls with simultaneous movement and jumping.
- Animated idle, run, jump, fall and celebration states.
- Lantern glow, ambient fireflies, pickup trails, checkpoint bursts and completion particles.
- Free checkpoint retries, optional hints, local progress, three star ratings and replay.
- Music and effects sliders, vibration, reduced effects and an in-game guide.
- Focus loss pauses gameplay; returning to the app requires Resume.

Keyboard controls: **A/D or arrows** to move, **Space/W/Up** to jump, **E/L** to toggle the lantern, and **Esc/P** to pause.

## Run locally

Install the exact standard Godot **4.5.1 stable** editor and matching export templates. Import `project.godot`, then run the main scene. No npm, database, API key or backend setup is needed.

```sh
godot --headless --editor --path . --import
godot --headless --fixed-fps 60 --path . tests/test_runner.tscn
godot --headless --fixed-fps 60 --path . tests/navigation.tscn
godot --headless --fixed-fps 60 --path . tests/traversal.tscn
godot --path .
```

The integration suite checks save recovery, progression, all level spawns, movement, jumping, lantern puzzles, checkpoints, death, retries, revives and menu flow. Traversal tests use the actual controller and physics to complete all ten levels. Tests restore the prior local save afterward. Run them in an isolated user-data environment when developing against valuable player data.

## Android export

Prerequisites: JDK 17, Android SDK platform 35, build tools 35.0.0, platform tools, NDK 28.1.13356709, Godot 4.5.1 and matching export templates. The generated Android build uses Gradle 8.13 and Android Gradle Plugin 8.6.1. Configure the Java SDK and Android SDK paths in Godot Editor Settings.

```sh
python3 scripts/prepare_android.py --template /path/to/4.5.1.stable/android_source.zip
mkdir -p build
godot --headless --path . --export-debug Android build/Little-Lantern-1.0.1.apk
```

The preset includes arm64-v8a, armeabi-v7a and x86_64, Android 8 or later, landscape orientation, immersive mode and disabled platform backup. `android/build` is generated and excluded from Git; `prepare_android.py` recreates the native integration deterministically. Build dependencies are downloaded by Gradle on first export.

The debug APK is for installation and testing. A Play release needs the publisher's signing setup, a release export, an incremented version code and a signed AAB. Signing credentials must remain outside version control. Remove x86_64 from a store build if emulator support is unnecessary.

For headless software emulation, use the emulator's `-gpu swangle` backend. The older `swiftshader_indirect` backend can reject Godot shaders because of a driver uniform-limit bug. The validation record covers native screen rendering, menu navigation, Android save creation, installation and the automated gameplay checks; physical-device performance still needs verification.

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
| `scripts/level_data.gd` | Ten authored layouts and validation |
| `scripts/save_service.gd` | Versioned local save, backup and recovery |
| `scripts/audio_service.gd` | Music and sound effects |
| `scripts/ad_service.gd` | Engine-facing advertising lifecycle |
| `native/android/LanternAds.java` | Optional Android advertising bridge |
| `tests/` | Integration and full-route traversal tests |
| `docs/` | Specification, art provenance and validation records |

Local saves live under Godot's `user://` directory. Uninstalling or clearing app data removes progress. This version has no cloud restoration or cross-device synchronization.

## Artwork and third party notices

The art was generated specifically for this game and normalized into game assets. The storyboard is a visual reference; the running game has its own reusable assets and animations. Ambient music and effects are original procedural audio. See `docs/ARTWORK.md`, `assets/licenses/GODOT.txt` and `assets/fonts/LICENSE.txt` for provenance and notices. No project-wide source licence has been selected.
