# Build validation

## Version 1.0.2 — 18 October 2026

Replaced the separate left and right arrow buttons with a left thumbstick. Drag horizontally for proportional movement and release to stop. A larger jump button sits at the right edge, with the lantern beside it. Keyboard controls remain available.

- 188 integration checks and 14 menu navigation checks pass; all ten level traversals pass.
- Drag dead zone, proportional speed, left and right movement, direction reversal, release outside the pad, finger ownership and simultaneous drag plus jump pass through viewport input events and real character physics.
- Focus loss, cancelled touches, stale drag events and HUD rebuilding release movement.
- Reviewed the rendered gameplay layout at 1280 by 720.
- Android Gradle build and signature verification pass. The signing identity matches the previous APK.
- The final APK's compiled resources also pass all 188 integration checks and 14 navigation checks.

Artifact: `Little-Lantern-1.0.2.apk`, version code 3, 105696855 bytes.
SHA256: `1c5bfc75ed6a4ffffddee584e8c90a935eab9372cffaf8791f58f3a3852ff2db`.

This patch has not been tested on a physical Android device. It remains a test-signed build with advertising disabled.

## Version 1.0.1 — 18 October 2026

The navigation regression reproduces engine errors in version 1.0.0 when a menu button frees its own signal emitter. Menus now hide immediately and are destroyed at the end of the frame. Loading interrupted by focus loss now opens paused, with Resume restoring gameplay. Restored checkpoints now capture the checkpoint flag before persisting, so repeated Continue does not lose the checkpoint.

- 179 integration checks and 14 navigation checks pass.
- Actual pointer events cover Play, level selection, repeated Continue and Resume.
- Focus loss during asynchronous loading and subsequent recovery pass.
- All ten real-physics level traversals pass.
- The verification script rejects engine runtime errors even if Godot returns zero.

Android Gradle export and APK signature verification passed. Version code is 2, version name is 1.0.1, and the signing certificate matches version 1.0.0. All 14 navigation checks also pass against the compiled game resources extracted from the final APK.

- File: `Little-Lantern-1.0.1.apk`
- Bytes: 105693564
- SHA256: `dfb2d073ce61981740a40a57521bfcd0f37f532100019c8606ec9971867702a9`

Native installation and Android input were not repeated for this patch. The physical-device performance and touch-feel limitations of the original validation remain. This is a test-signed APK; advertising remains disabled.

## Version 1.0.0 baseline

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
