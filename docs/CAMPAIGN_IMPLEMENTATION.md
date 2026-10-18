# Little Lantern 2.0.0 campaign

## Implemented scope

Forty distinct authored routes replace the classic repeated campaign. Forest levels 1–10 teach locks, light, weights and moth lures. Water levels 11–20 introduce swimming, floating cargo, conserving cistern transfers, currents and rafts. Fire levels 21–30 introduce heat, vents, decoys, lava and recoverable collapsing routes. Highlands levels 31–40 introduce temporary ice, wind, gliding and mixed elemental puzzles.

Every level has an authored puzzle dependency graph, checkpoints, an optional memory, free hints and a puzzle journal. Every tenth level ends with a three-phase guardian. Twelve ordinary enemy families use distinct movement and light responses. Resetting a puzzle restores recoverable mechanisms without discarding completed permanent objectives.

The design briefs live in `campaign_briefs.py`. `scripts/build_campaign.py` compiles the authored geometry and mechanisms into `assets/data/campaign.json`; `level_data.gd` validates runtime IDs and geometry uniqueness. World, hero, enemy and crate scripts implement the runtime rules. Progress stays on the device; no account or developer backend is used.

## Validation

The source suite passes **475 assertions**: 40 control/travel/state checks, 14 navigation checks and 421 campaign checks across all forty levels. It exercises simultaneous touch ownership, save migration and real file reload, moving-platform carriage, swimming, gliding, cistern conservation, wrong-decoy recovery, brittle platforms, winch recovery, timed ice, receiver light exposure, actual crate pushes, guardian impacts, checkpoint retry and exit gating.

Campaign scenarios move the character to puzzle fixtures to isolate mechanisms. These assertions are not a claim that every route has been manually played end to end. Placement auditing found no stranded interaction fixtures. Desktop captures inspect each region, journal and map. Exported resource tests and APK signature metadata are recorded separately in `VALIDATION_2.md`.

Physical Android installation, long sessions and performance on low-end devices remain unverified for 2.0.0. This is a debug-signed installable test build. Advertising remains disabled until publisher configuration is supplied; no advertising revenue is claimed.
