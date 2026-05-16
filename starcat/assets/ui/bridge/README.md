# Bridge UI Asset Pack

This folder contains the shared bitmap surfaces for the Starcat minimal command UI pass.

Files in this pack are reused by:

- `starcat/scenes/HudLayer.tscn`
- `starcat/scenes/ui/ActionButton.tscn`
- `starcat/scenes/ui/Chip.tscn`
- the major card scenes under `starcat/scenes/ui/`

Visual rules:

- Assets are cropped from a generated transparent UI sheet at `starcat/assets/ui/source/generated_ui_sheet_alpha.png`.
- The sheet is generated with strict reference to three UI directions: Arknights-like slanted command tiles,
  Stellaris-like dense resource and fleet HUD strips, and Death Stranding-like cyan holographic map overlays.
- The palette is dark graphite surface, cyan linework, white telemetry, and amber-orange action accent.
- Every exported PNG keeps a transparent background so Godot can layer panels over starfields and map views.
- No instructional copy, embedded labels, logos, characters, or baked gameplay text belongs in the texture source.
- Thin rectangular divisions, low corner radius, and compact panel proportions stay close to strategy UI references.
- Orange accent is reserved for active, selected, urgent, or primary actions.
- `starcat/tools/recolor_bridge_ui.py` is the single export path. It crops the generated transparent UI sheet,
  applies lightweight state tuning, deletes obsolete menu textures, and writes the bridge/menu PNGs used by scenes.
