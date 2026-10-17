# Little Lantern predevelopment specification

This is the proposed baseline prepared before implementation. See README.md and VALIDATION.md for the implemented scope, pinned versions and actual verification.

# Little Lantern Technical Specification

Android 2D puzzle adventure game
Version 1.0 • 17 October 2026 • Predevelopment proposal

Build a single player adventure in which a small forest creature uses a lantern to reveal paths, power mechanisms and rescue fireflies. This document translates the six screen storyboard into a proposed engineering baseline for implementation, testing and Android delivery. No game code or playable build has been produced as part of this specification.

### 1 Product scope and assumptions

Confirmed direction: a 2D adventure intended to earn advertising revenue, without a developer operated backend. The Little Lantern storyboard is the visual reference. Godot, the ten level scope and the parameters below are recommendations, not previously approved implementation decisions.

| Area | Proposed first release |
| --- | --- |
| Platform | Android phones in landscape orientation; touch first |
| Content | 10 handcrafted levels across forest, cave and ruins themes |
| Session | Approximately 1 to 3 minutes per level; optional replay |
| Progress | Local device save; no account, cloud sync or leaderboard |
| Monetization | Optional rewarded hints and revives; limited interstitials |
| Technology | Godot 4 stable, GDScript, Compatibility renderer |
| Distribution | APK for testing; signed AAB for Google Play |

### Release boundaries

Include movement, jumping, lantern puzzles, fireflies, checkpoints, level selection, settings, sound and a short interactive tutorial. Exclude multiplayer, combat systems, purchases, procedural campaigns, remote content, seasonal events and cross device recovery. New content ships through app updates.

### Success criteria

A new player can learn the controls and finish the first level without an ad. All ten levels can be completed offline. Saving survives a normal app restart and an upgrade. Ads never interrupt active movement, and a missing ad never prevents progression. Revenue and audience growth are outcomes to measure after release, not guaranteed deliverables.

## 2 Gameplay rules and level progression

### Core loop

Choose an unlocked level, explore platforms, collect optional fireflies, solve the required lantern puzzle, activate checkpoints and reach the exit. The next level unlocks on completion regardless of score. Every level has five uniquely identified fireflies. Replay can improve the saved best result without reducing previous progress.

### Movement and interactions

Use CharacterBody2D for the player and fixed physics updates. Initial tuning values are 220 world units per second horizontal speed, 1100 units per second squared gravity and minus 420 units per second jump impulse. Treat these as prototype values. Add 100 milliseconds of coyote time and 120 milliseconds of jump buffering. Both left and right held together produce zero horizontal intent.

Support moving and jumping simultaneously with separate touch identifiers. Releasing jump early reduces upward velocity for a shorter jump. Prevent repeated airborne jumps. Moving platforms transfer motion consistently; hazards trigger one death transition, clear held inputs and suppress duplicate collision events.

### Lantern system

The lantern is an unlimited toggle with no paid fuel or energy timer. A front facing cone reveals nearby bridge segments and activates receivers only when within configured range and unobstructed by a solid wall. Gameplay uses deterministic overlap and ray checks; the visual glow alone does not decide puzzle state.

Revealed bridges remain solid once activated until the attempt resets, avoiding falls caused by turning away. Receivers latch after 0.5 seconds of continuous illumination and power a linked gate. Enemies use simple patrol and investigate states, moving toward visible lantern light only when line of sight is clear. Introduce one enemy type after the tutorial.

### Death and checkpoints

Free Retry restarts at the last checkpoint, or the level start. Capture checkpoint ID, collectibles collected so far and persistent puzzle flags at activation. Retry restores that snapshot; deaths increment and elapsed attempt time continues. Restart Level resets the attempt. A rewarded revive restores the most recent safe grounded position and current puzzle state with two seconds of hazard protection, at most once per attempt. Fall back to the checkpoint if that position is unsafe.

### Completion and rating

The exit checks required gate and puzzle flags. Stars are cumulative: one for completion, a second for all five fireflies and a third for all five with zero deaths. A revive does not erase a death. No speed rating is used. Commit progress before showing results or requesting an interstitial. After level ten, show campaign completion and offer replay.

## 3 Screens controls and lifecycle

| Screen | Required behavior |
| --- | --- |
| Home | Play resumes the current unfinished level or opens the map. Settings and sound controls remain visible. |
| World map | Show 10 nodes, completed stars and a clearly selected level. Locked nodes explain the previous level requirement. |
| Gameplay | Fireflies at top left, level label at top centre, pause and hint at top right. Movement bottom left; jump and lantern bottom right. |
| Pause | Resume, Restart Level, Settings and World Map. Confirm restart or leaving when unsaved attempt progress will be lost. |
| Death | Free Retry is the primary action. Offer the distinct rewarded revive only when eligible and loaded. |
| Results | Show best rating and firefly count. Next Level, Replay and Map; replace Next with campaign completion on level ten. |
| Settings | Music and effects sliders, sound and vibration switches, reduced effects option, privacy entry and confirmed Reset Progress. |

### Responsive and accessible presentation

Use a 1280 by 720 logical canvas and an expanding aspect strategy. Anchor the HUD to safe area margins, including display cutouts and gesture regions. The camera and level geometry must prevent wider screens from revealing unfinished scenery or bypassing puzzles. Test 16 to 9, 19.5 to 9 and 20 to 9 displays.

Touch targets should be at least 48 density independent pixels on device. Provide icon plus text for menu actions, high contrast labels and visual feedback for every press. Use symbols and motion as well as colour to communicate powered receivers and hazards. Reduced effects disables flashes and camera shake. No menu action depends on a timed response.

### Tutorial and loading

Teach movement, jump, lantern reveal and a receiver puzzle through safe interactions in levels one and two. Tutorial prompts pause hazards when necessary and can be dismissed. Load the next level asynchronously with visible progress; prevent double navigation and provide a recoverable error screen if a scene fails.

### App interruption behavior

Android Back pauses gameplay and closes the topmost menu first. Backgrounding, focus loss or an incoming interruption pauses simulation, clears input and saves committed progress plus the current checkpoint snapshot. On return, show Resume instead of moving immediately. Restarting the process restores the checkpoint, not an exact midair position. Ad overlays pause simulation and audio through the same pause controller; dismissing an ad must not override a separate background pause.

## 4 Engine architecture and contracts

Pin one released Godot 4 stable version and matching export templates after an Android proof build. Record the exact engine, JDK, Android SDK, Gradle and ads dependency versions in the repository. Do not rely on unstable documentation or a floating plugin branch. Godot Android plugins integrate through the Android build system [1, 2].

| Component | Responsibility |
| --- | --- |
| AppState | Screen transitions and states: boot, menu, loading, playing, paused, dead and results |
| LevelController | Spawns, puzzle registry, checkpoints, attempt lifecycle and completion |
| PlayerController | Input intent, movement, animation and lantern orientation |
| LanternController | Detection cone, occlusion checks, reveal events and visual light |
| Puzzle components | Receiver, gate, hidden bridge, moving platform, hazard and exit scenes |
| SaveService | Validation, migrations, checkpoint serialization and recovery |
| AdService | Engine facing adapter for rewarded and interstitial lifecycle |
| AudioManager | Music and effects buses, focus behavior and volume settings |

### Scene and service boundaries

Use reusable .tscn scenes and typed GDScript. A level contains World, PlayerSpawn, PuzzleRoot, Collectibles, Checkpoints, Exit and CameraBounds. The HUD lives in a CanvasLayer. Puzzle scenes reference stable object IDs instead of relying on fragile node paths. Use autoloads only for cross scene services such as AppState, SaveService, AudioManager and AdService.

LevelController consumes signals such as firefly_collected(id), checkpoint_activated(id), receiver_powered(id), player_died(reason) and exit_reached(). It owns completion and snapshot rules. UI emits intentions; it does not write progress directly. LanternController never calls advertising APIs.

### Advertising adapter

Expose initialize, is_rewarded_ready, show_rewarded(placement, attempt_token), is_interstitial_ready and show_interstitial. Return signals for loaded, failed, shown, dismissed and reward_earned. A stub adapter supplies deterministic success and failure paths in desktop tests. The Android implementation marshals callbacks to the engine thread and rejects callbacks for expired attempts.

### Repository layout

Organize res:// into scenes/app, scenes/player, scenes/puzzles, scenes/ui, levels, scripts/services, scripts/gameplay, assets/art, assets/audio, assets/fonts, addons and tests. Store level resources and export presets in version control; exclude generated .godot caches, local Android SDK paths and signing secrets. Keep large original art in a controlled source asset location with an asset manifest.

## 5 Level data and local persistence

### Level resource contract

Represent each level with a typed Godot Resource containing level_id, order, theme, scene_path, previous_level_id, firefly_ids, checkpoint_ids and required_exit_flags. Runtime object IDs must be unique within the level and stable across releases. A validator rejects missing scenes, duplicate IDs, unreachable spawn configurations and references to nonexistent puzzle targets before export.

| Save field | Type and validation |
| --- | --- |
| schema_version | Integer; migrate known older schemas and preserve unsupported newer files |
| revision | Nonnegative integer; increment only after a successful save transaction |
| levels | Dictionary keyed by known level ID; completion boolean, best stars 0 to 3 and best fireflies 0 to 5 |
| resume | Optional level ID, checkpoint ID, collected ID set, puzzle flags, deaths and elapsed seconds |
| settings | Audio values 0 to 1; vibration and reduced effects booleans |
| tutorial_flags | Known tutorial IDs mapped to completion booleans |

### Storage and recovery

Use FileAccess with JSON at user://progress.json and ConfigFile for settings where appropriate [3]. Save small structured records rather than arbitrary serialized nodes. Validate types, limits and known IDs on read; reject nonfinite numbers. Recompute unlocked levels from completions rather than trusting a stored unlocked count.

Write to a temporary file in the same directory, flush and close, reopen and validate, retain the previous valid file as a backup, then replace the primary using the platform supported rename operation. Check every filesystem result. On startup choose a valid primary; otherwise recover the backup or a complete valid temporary file. If all fail, preserve damaged files and create defaults with a brief recovery message. This reduces corruption risk but cannot guarantee survival of every device storage failure.

Save after checkpoint activation, completion, changed settings and backgrounding. Avoid writes each frame. If a write fails, retain progress in memory, show a nonblocking save warning and retry at the next safe point. Never report a successful persistent save until the write has completed.

### Progress integrity and limits

Migrations are sequential and tested with fixtures; retain a pre migration copy. Ignore removed object IDs safely and reset an incompatible checkpoint to the level start. Best results combine monotonically with previous best values. A new installation or cleared app data starts fresh; cross device recovery is outside scope. Configure Android backup explicitly so platform backup behavior matches the published promise. Local files and client rewarded callbacks are not tamper proof; no competitive or cash value depends on them.

## 6 Art audio and performance

### Asset production

The storyboard is a concept reference, not a sprite sheet or a guarantee of identical rendered detail. Produce separate layered forest, cave and ruins backgrounds; modular terrain tiles; the player; one enemy; five puzzle object types; collectibles; interface icons; and effects. Use original or appropriately licensed artwork and audio. Keep source, licence, attribution and permitted commercial use in an asset manifest.

The player needs idle, run, jump, fall, land, lantern toggle, hurt and celebration animations. Align sprite pivots and frame sizes. Collision shapes are simpler than painted outlines. Use a small set of layered backgrounds and reusable terrain modules to keep the illustrated look affordable. The first playable level sets the quality baseline before producing all themes.

### Rendering strategy

Begin with the Compatibility renderer for broad device support. Use a textured glow and a limited number of PointLight2D nodes. Keep lantern gameplay detection independent of lighting and graphics quality. Limit overlapping transparent layers, shadow casters and particle counts. Package textures in atlases where practical; cap oversized backgrounds and load only the active theme. Pool frequently spawned effects after profiling demonstrates a benefit.

| Metric | Initial engineering target |
| --- | --- |
| Frame rate | 60 FPS target on a selected midrange device; stable 30 FPS fallback on the minimum device |
| Physics | 60 fixed updates per second with movement independent of rendered frame rate |
| Memory | Peak process memory under 300 MB on the reference device |
| Startup and loading | Cold start under 5 seconds; normal level transition under 2 seconds |
| Download | Aim below 100 MB compressed for the first release |
| Device baseline | Proposed Android 8 or later and 3 GB RAM; raise minimum if selected dependencies require it |

These are acceptance targets to measure on named devices, not measured results. Benchmark a 15 minute session containing light puzzles, effects, level transitions and ads. Track frame pacing, memory growth, thermal slowdown and background recovery. Lower particles, background detail and shadow quality before changing puzzle behavior.

### Audio

Use separate music, effects and UI buses. Include three ambient loops plus jump, landing, pickup, switch, gate, death and completion cues. Limit simultaneous voices and normalize loudness. Pause or duck audio during ads and interruptions; restore the previous settings afterward. Sound must support, rather than replace, visual cues.

## 7 Advertising and privacy implementation

No developer backend is required for the proposed offline game. AdMob remains an external network service. Use one vetted Godot Android ads plugin only if its licence, engine compatibility, current SDK support and consent integration pass a proof build; otherwise create a small Kotlin bridge. Plugin selection is an unresolved dependency, not an assumed completed integration.

### Rewarded behavior

A hint reveals the next relevant receiver or hidden bridge without solving the whole level. A revive preserves current progress as defined on page two. Clearly state the reward before the player chooses an ad. Grant it exactly once only after the SDK earned reward callback [4]. Dismissal alone grants nothing. Carry a unique request token and placement so duplicate or delayed callbacks cannot reward the wrong level or attempt.

Record the earned outcome when received; apply it once the game is safely visible. Handle reward and dismissal callbacks without assuming their order. A resumed or restarted attempt invalidates stale tokens. A process killed before an earned event is safely recorded may lose that transient reward; free Retry remains available. There is no server verification in this scope.

### Interstitial rules

Proposed frequency: eligible after every third completed level, a minimum 120 seconds since the last full screen ad, and no forced ads during the first three minutes. These are product defaults to tune, not Google prescribed values. Show only after results when the player chooses Next or Map, at a predictable level transition [5]. Skip if a rewarded ad appeared in the previous 120 seconds. Never queue an ad to appear later during gameplay.

Preload without blocking navigation. Show only a ready, valid ad; otherwise continue immediately. Failures release the pause lock and restore controls. Permit one load per placement at a time, with bounded exponential retry backoff while online and foregrounded. Refresh expired ads according to the selected SDK. No banners, startup interstitials or ads on every death.

### Consent and release configuration

Use UMP consent information updates and required forms, and gate ad requests on canRequestAds. Provide a privacy options entry when required and avoid duplicate initialization [6]. Gameplay remains accessible if consent collection fails or ads cannot be requested. Use test IDs and test devices throughout development; never test by clicking live ads [4].

Before public release, configure AdMob app and placement IDs, a public privacy policy, applicable consent messages, app ads verification requirements, Play Data safety disclosures and the intended audience. Cute artwork alone does not determine the audience setting. Review the selected SDK and child audience requirements before enabling live ads. There are no advertising revenue estimates in this specification.

## 8 Android builds delivery and security

### Toolchain and integration gate

Install the pinned Godot editor and export templates, the JDK and Android SDK required by that release, and a Gradle Android export configuration [1]. Prove an installable arm64 build on a physical phone before full content production. Add the selected ads bridge and UMP next, then verify test ads, consent, offline fallback and interruption recovery. Resolve this gate before expanding to ten levels.

### Build variants

| Variant | Purpose and configuration |
| --- | --- |
| Development | Debug signing, test ads, diagnostic logs and desktop ad stub |
| Internal QA | Release mode APK with test ads; verify production optimizations and install upgrades |
| Production | Signed release AAB with approved live ad configuration; APK when direct installation is required |

Use distinct configuration resources for ad IDs and logging. Ad placement identifiers are not secret keys, but signing passwords and keystore material must never be committed. Keep the release signing identity backed up securely. Increment Android versionCode for each distributed update and use a readable versionName. Final package ID and publisher identity must be selected before store configuration.

### Export and validation

Choose minimum and target Android API levels only after verifying the engine, ads SDK and current Google Play requirements at release time. Enable required architectures, landscape orientation, display cutout handling and only necessary permissions. Internet and network state support ads; no contacts, location or broad storage permission is required by the game design. Audit the final merged manifest because plugins may add entries.

Generate the APK or AAB from the recorded dependency set, inspect signature and version metadata, install cleanly, launch and exercise the full flow. Test updating over a previous signed build while preserving saves. Deliver the exact tested artifact, checksum, version and concise release notes. An APK build success alone is not evidence of successful installation or working ads.

### Repository and operational safeguards

Run scene import, script parse and level data validation in automation. Add focused tests for save migration, progression and advertising callbacks. Separate distribution from building; store publishing requires the owner’s authorized release step. No repository, signing configuration or publishing account has been supplied for this game yet.

Keep logs local and omit advertising identifiers, consent strings and personal information. Initial measurement can use AdMob reporting and optional local QA counters; no remote analytics or crash collection is included. Reevaluate that choice after launch if product decisions require player retention data, with corresponding disclosure and consent review.

## 9 Verification milestones and references

| Test area | Release acceptance |
| --- | --- |
| Gameplay | All ten levels finish without ads; puzzle reset, collision, jump and checkpoint rules hold |
| Input and UI | Multitouch works; interrupted touches clear; controls fit all target ratios and cutouts |
| Persistence | Restart and upgrade preserve progress; corrupt, missing, old schema and failed writes recover |
| Advertising | Test earned, cancelled, duplicate, stale, no fill, timeout, offline and background callbacks |
| Lifecycle | Pause, Back, audio focus, process restart and ad return never resume unexpectedly |
| Performance | Meet agreed device budgets; no steady memory growth in a 15 minute session |
| Distribution | Signed artifact installs, launches and upgrades; production configuration is reviewed |

### Implementation milestones

M1 Foundation: pin toolchain, repository structure and Android proof build. M2 Vertical slice: one polished forest level with movement, lantern, checkpoint, save and results. M3 Integration: test ads, UMP and lifecycle edge cases on a physical phone. M4 Content: expand to ten validated levels and three themes. M5 Release candidate: complete device QA, signing, disclosures and tested APK or AAB. Each milestone exits through its working behavior, not a promised date.

### Decisions carried into implementation

Defaults are Android, landscape, Godot 4, ten levels, local saves and the monetization limits above. Still to establish: repository, final package ID, reference devices, exact dependency versions, asset production plan and advertising plugin. Publisher accounts, live ad IDs and signing credentials are needed for release preparation, not for the first desktop prototype. No build or gameplay tests have been run; this deliverable is the predevelopment specification.

### Official technical references

1 Godot Android export
https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html

2 Godot Android plugins
https://docs.godotengine.org/en/stable/tutorials/platform/android/android_plugin.html

3 Godot saving games
https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html

4 Google rewarded ads
https://developers.google.com/admob/android/rewarded

5 AdMob interstitial placement
https://support.google.com/admob/answer/6201350

6 Google UMP consent
https://developers.google.com/admob/android/privacy

References checked 17 October 2026. SDK interfaces and store rules must be checked again against the exact versions selected for implementation.
