# Artwork and audio provenance

The visual target is the Little Lantern storyboard created in this conversation. The game uses separate original generated assets rather than displaying the storyboard as gameplay.

## Production artwork

The original painted images below were generated with OpenAI image generation for this project on 17 October 2026. No downloaded commercial game sprites or third party character references were used.

| Asset | Source and processing | Runtime purpose |
| --- | --- | --- |
| `forest.png` | Generated moonlit forest panorama | Home, map and forest levels |
| `world-0.png` | Upper half of a generated paired panorama | Cave levels |
| `world-1.png` | Lower half of the same paired panorama | Ruins levels |
| `hero_atlas_source.png` | Generated four by four transparent character sheet | Source artwork retained in Git |
| `hero_atlas.png` | Sheet aligned to a 1280 by 1280 cutting grid | Intermediate reference retained in Git |
| `hero.png` | Sixteen trimmed and padded frames, 352 by 320 pixels each | Runtime animation atlas |
| `platform.png` | Cropped and trimmed from generated object atlas | Modular terrain |
| `gate.png` | Cropped and trimmed from generated object atlas | Exit gate |
| `receiver.png` | Cropped and trimmed from generated object atlas | Sun receiver puzzle |
| `checkpoint.png` | Cropped and trimmed from generated object atlas | Checkpoint shrine |
| `icon.png` | Character frame over a dark teal gradient | Android launcher icon |

Structural slicing, trimming, padding, atlas assembly and icon composition used ImageMagick. Visual validation included alpha compositing over a dark background, engine screenshots and gameplay captures. Sprite animation changes pose by frame; it is not a static image moved around the screen. The run cycle has four frames, idle four, jump two, fall one and celebration four, with some source poses reused by state.

## Generation specifications

Forest: a premium hand painted moonlit teal forest with a full moon, layered mountains, mossy ruins, distant golden windows, waterfalls, navy shadows and an open foreground for separately rendered platforms. No character, text, UI or foreground floor.

Character: an original cream coloured fennec-like forest creature, large peach inner ears, short legs, fluffy tail, teal scarf and a brass lantern. Transparent four by four atlas, consistent right facing profile and scale, idle, running, jumping and celebration poses, no external glow or scenery. The earlier thirty frame concept sheet is not used by the game.

Cave and ruins: two equally sized panoramic scenes stacked vertically. The cave has teal mist, stalactites, waterfalls, luminous mushrooms and ancient carvings; the ruins have broken arches, moonlight, vegetation and distant golden doors. Both leave the lower foreground open for gameplay geometry.

Objects: a transparent atlas containing a flat mossy stone platform, ornate barred sun gate, sun receiver pedestal and amber checkpoint shrine. Cool teal stone shadows and amber highlights match the illustrated backgrounds.

These specifications document the generation direction; they are not a claim that every frame is physically identical or that AI output establishes a particular copyright status. Asset hashes and dimensions are recorded in `assets-manifest.json`.

## Runtime effects

Ambient fireflies, glowing pickups, lantern light, reveal particles, checkpoint bursts, dust and the moth enemy are drawn by the engine. Their positions and lifetimes animate during play. Reduced effects limits particles, removes ambient particles and suppresses protection flashing and celebration bobbing.

## Audio and fonts

The ambient loop and all sound effects were synthesized for the project from sine waves and envelopes. They use no stock music or externally sampled recordings. Music loops and effects have independent volume controls.

`Story.ttf` is DejaVu Serif and `Interface.ttf` is DejaVu Sans. Their licence is retained at `assets/fonts/LICENSE.txt` and accessible in the game's notices screen. Godot's MIT notice is at `assets/licenses/GODOT.txt`.

## Version 2 elemental regions

Three original backgrounds were generated separately with OpenAI image generation on 18 October 2026, then inspected in the engine:

| File | Generation direction |
| --- | --- |
| `assets/art/water.png` | Moonlit flooded ruins, waterfalls, teal river and submerged arches |
| `assets/art/fire.png` | Volcanic forge, basalt arches, lava light and orange smoke |
| `assets/art/highlands.png` | Snowy observatory, distant spires, aurora and icy highlands |

Shared direction: painterly storybook landscape, distant and middle scenery, quiet dark lower foreground for platforms, no characters, enemies, text or UI. These are separate scenes rather than recoloured forest backgrounds. Regional enemies, guardians, elemental zones and puzzle props use animated engine drawing; the hero retains its existing sprite atlas.

`river.wav`, `ember.wav` and `sky.wav` are original procedural loops generated by `scripts/build_audio.py`, without external samples.
