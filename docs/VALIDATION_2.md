# Version 2.0.0 validation — 18 October 2026

- Godot 4.5.1 Compatibility renderer; Android version code 4, package com.rendermind.littlelantern.
- Source: 40 control/state assertions, 14 navigation assertions, 421 campaign assertions; all passed.
- Exported APK assets extracted to a separate directory and the same 475 assertions passed against the packaged scripts/resources. No engine script errors reported.
- Forty campaign entries verified in the APK. Duplicate ZIP paths and included test fixtures checked; tests are excluded from the distributed APK.
- Screens inspected: forest, river, volcanic region, highlands, chapter map and journal. Interaction placement audit returned no stranded fixtures.
- APK signature verified with apksigner. Certificate SHA-256: ea6f073862fce82b3aae0c80f81e4c537825813c406bfa882a14bc5957abf3da (same test certificate as the previous build).
- Android minimum API 26, target API 35; armeabi-v7a, arm64-v8a, x86_64.
- APK bytes: 111368065. SHA-256: b812b2b9c21c38200d6db95f0d3ee6966c5970dde8872f42c4ee1e8058f226de.

Automated campaign checks isolate puzzle mechanisms and are not full manual end-to-end traversal of every route. Physical Android installation, sustained frame rate and low-end memory behaviour have not been checked for this version. Ads remain disabled. This is a debug-signed test APK, not a Play release.
