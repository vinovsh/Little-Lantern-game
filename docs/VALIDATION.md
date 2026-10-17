# Build validation

Build date: 17 October 2026. Version: 1.0.0. Package: `com.rendermind.littlelantern`.

## Results

| Check | Result |
| --- | --- |
| Godot project import and script compilation | Passed with Godot 4.5.1 |
| Integration checks | 179 passed, zero failures |
| Full route traversal | All ten levels completed using the real controller and physics |
| Simultaneous touch movement and jump | Passed through viewport touch events |
| Local save, reload, invalid types and backup recovery | Passed |
| Ad lifecycle simulation | Earned, cancelled, duplicate, stale and late callbacks passed |
| Completed level background save | Does not restore an obsolete checkpoint |
| Desktop visual review | Home, map, forest, cave, ruins, bridge, puzzle, results, death and settings reviewed |
| Wide viewport review | Gameplay and menus captured at 1600 by 720, alongside 1280 by 720 checks |
| Native advertising bridge compilation | Passed with GMA 25.5.0 and UMP 4.0.0 |
| Android Gradle APK build | Passed |
| APK signature verification | Passed using APK Signature Scheme v2 |
| Android installation | Passed on the Android 9 x86_64 software emulator |
| Native Android screens | Home, world map and level one rendered successfully using the ANGLE backend |
| Native Android menu navigation | Home to map and level selection passed through injected touch input |
| Native Android save creation | Level one resume data was written and read from the app private files directory |
| Android vibration permission | Declared and verified in the final APK manifest |
| APK reinstall with preserved data | Passed using `adb install -r` with the same signing identity |
| Packaged game assets | Extracted from the actual APK and launched successfully in the desktop engine |
| Live advertising | Disabled; no publisher identifiers supplied |

The traversal driver collected all five fireflies in levels three through ten and four in levels one and two. It verifies finishability, not an exhaustive search of every collectible route. Level one and two's higher optional firefly requires a separate jump.

The host has no KVM acceleration. The legacy `swiftshader_indirect` emulator backend failed to compile Godot shaders, matching the driver issue discussed in [Godot issue 109550](https://github.com/godotengine/godot/issues/109550). Switching the emulator to `-gpu swangle` allowed the native Android home, map and first level to render. Cold startup also triggered emulator System UI ANRs. This environment is unsuitable for measuring real-world frame rates, startup time, touch latency, audio or physical vibration. Those checks still need representative physical devices.

## Artifact

- File: `Little-Lantern-1.0.0.apk`
- Type: debug-signed testing APK, not a Play production release
- Android minimum: API 26
- Android target: API 35
- ABIs: armeabi-v7a, arm64-v8a and x86_64
- SHA256: `1ccde0e5f693987ae779812376c5f21913904f8cb6d605bb19c8e4a68b94a16a`

The APK excludes generated Android build files, native source, tests and documentation. Engine and font notices are included. Native library compression is enabled for direct APK delivery.

## Before publishing

Verify performance, touch feel, interruption recovery and audio on representative physical Android devices. Configure the publisher's AdMob application and placement identifiers, applicable consent messages and disclosures. Use the publisher's release signing configuration and a signed AAB. Revenue, fill rates, store approval and real-world retention have not been measured or promised.
