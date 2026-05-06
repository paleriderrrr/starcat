# Starcat HUD Bridge UI Redesign

Date: 2026-05-06
Project: `starcat`
Scope: Main HUD and major sub-cards
Status: Approved for planning review

## 1. Goal

Upgrade the current Godot HUD into a cohesive anime-realistic sci-fi "cold bridge" presentation with restrained neon highlights.

This is a UI polish and layout-tuning pass, not a gameplay or interaction redesign. The work should improve visual hierarchy, cohesion, readability, and perceived production value while preserving the current screen architecture and existing control flow.

## 2. Confirmed Constraints

- Visual direction: cold bridge style with selective neon accents
- Scope: main HUD plus major sub-card surfaces
- Layout strategy: conservative rearrangement
- Engine/runtime: Godot 4.6 Control-based UI
- Existing structure to preserve:
  - top resource/status bar
  - right-side detail drawer
  - center modal
  - bottom navigation strip
  - card-based content panels
- Existing interaction logic remains in place unless a minimal layout-driven hook change is required

## 3. Current Project Context

The current game is a Godot 4X strategy prototype with:

- `scenes/Main.tscn` composing `StarMap` and `HudLayer`
- `scenes/HudLayer.tscn` defining the main control shell
- `scripts/HudLayer.gd` building most dynamic HUD content
- reusable UI scenes under `starcat/scenes/ui/`

The project has already gone through several HUD readability and navigation passes. That means this redesign should build on the existing component system rather than replace it with a new UI architecture.

## 4. Design Intent

The HUD should feel like the command interface of a high-end flagship bridge:

- dark, cool, precise, metallic
- calm by default, with strong focus cues only when needed
- readable at a glance during long strategy sessions
- clearly layered between passive information, active controls, and urgent status

The visual target is not cartoon-neon overload. The anime-realistic influence should come through in polish, shape language, lighting restraint, and premium sci-fi detailing rather than exaggerated saturation.

## 5. Recommended Approach

### Option A: Pure Reskin

Replace only colors, borders, shadows, and decorative textures while preserving all sizing and structure.

Pros:

- lowest implementation risk
- fastest turnaround

Cons:

- limited increase in bridge identity
- existing spacing and hierarchy weaknesses remain visible

### Option B: Unified Reskin + Light Rearrangement

Keep the current HUD frame, but retune component dimensions, spacing, alignment, panel proportions, and state styling while integrating a shared visual asset system.

Pros:

- strong visual improvement without rewriting UI logic
- best balance between impact and regression risk
- aligns with the requested conservative rearrangement

Cons:

- still constrained by the current shell layout

### Option C: Near-Rebuild Upgrade

Retain functionality but reorganize much more of the surface layout and card flow.

Pros:

- strongest visual transformation

Cons:

- higher integration risk
- unnecessary for the requested scope

### Recommendation

Use Option B.

It fits the requested scope, preserves current architecture, and still allows meaningful improvements to perceived quality and usability.

## 6. Visual System

### 6.1 Style Keywords

- cold bridge
- armored glass
- tactical console
- restrained holographic glow
- premium sci-fi instrumentation

### 6.2 Palette Strategy

Base colors:

- near-black navy
- blue-gray metal
- desaturated steel

Primary accent:

- cold cyan / ice blue

Secondary accent:

- restrained magenta-violet for selected navigation or tech emphasis

Semantic accents:

- green for positive gain and diplomatic stability
- amber for caution
- red for threat and hostile escalation

Accent color use must remain sparse. Most surfaces should read as dark metal or smoked glass, with glow reserved for interaction states, focus, and critical information.

### 6.3 Surface Language

- panel faces use dark translucent layers with metallic framing
- corners stay controlled and engineered rather than playful
- thin illuminated seams and technical linework reinforce a bridge-console feel
- shadows should create depth, not softness
- borders should separate modules clearly against the starfield background

### 6.4 Typography and Hierarchy

- primary titles: bold, clear, command-console tone
- metadata: lighter, smaller, cooler
- values and warnings: highest contrast
- avoid decorative clutter that competes with numbers and action labels

## 7. HUD Layout Changes

This pass preserves the existing four-zone shell while tuning proportions and spacing.

### 7.1 Top Bar

Keep the top horizontal strip, but consolidate it into a more coherent bridge status beam:

- left: turn and era
- center: four resource chips as a grouped operational block
- right: utility action such as label toggle

Adjustments:

- tighten spacing consistency
- strengthen grouping between related chips
- make chips feel like embedded instrumentation rather than isolated pills

### 7.2 Right Drawer

Keep the drawer on the right, but style it as a tactical side console:

- stronger header zone
- clearer separation between title, summary, scroll body, and primary action
- thicker visual weight than the current plain panel

Adjustments:

- retune width within the current responsive behavior
- slightly increase internal rhythm and contrast
- preserve scroll-based content flow

### 7.3 Center Modal

Keep the modal centered, but convert it into a command terminal presentation:

- stronger title bar
- more distinct body container
- clearer close action
- improved separation between long-form content and utility controls

### 7.4 Bottom Navigation

Keep the navigation at the bottom:

- unify tab button proportions
- make active state sharper and more readable
- visually connect main tabs and fleet tabs into one command strip

Adjustments:

- preserve current navigation logic
- improve spacing, consistency, and selected-state contrast

## 8. Component System Changes

### 8.1 Shared Component Family

The following should share one master visual language:

- action buttons
- resource chips
- section titles
- summary cards
- info cards
- status cards
- feed cards
- diplomacy cards
- fleet cards
- build queue cards
- tech cards

Shared traits:

- unified panel framing
- consistent title treatment
- standardized spacing scale
- predictable state colors
- consistent hover/pressed/selected behavior

### 8.2 Card Variants

Cards should be unified first, then lightly differentiated by context.

Examples:

- tech: cool cyan with limited violet support
- diplomacy: cyan-green emphasis
- fleet/combat: icy blue emphasis
- alerts/conflicts: red or amber accents

The differentiation should come from restrained edge lighting, status bands, or icon framing rather than entirely separate card designs.

### 8.3 Button System

Buttons should be restyled into bridge-console controls:

- default buttons: dark glass + subtle edge light
- primary buttons: brighter cyan focus
- danger buttons: controlled red emphasis
- active/toggled buttons: high contrast filled state

The button silhouette should remain compatible with the current scene structure and Godot theme overrides.

## 9. Asset Strategy

This redesign includes generating new local UI bitmap assets and integrating them into the project.

Priority asset groups:

- panel background plates
- card shell textures
- button base textures and active states
- tab strip/segment textures
- modal and drawer framing elements
- optional subtle HUD ornaments for headers or separators

Integration principles:

- assets should be reusable across multiple scenes
- prefer a small coherent asset pack over many bespoke one-off images
- preserve performance and avoid oversized textures

## 10. Integration Plan

Implementation should focus on low-risk attachment points.

Primary targets:

- `starcat/scenes/HudLayer.tscn`
- shared card scenes under `starcat/scenes/ui/`
- `starcat/scripts/HudLayer.gd` only where theme/state behavior needs adjustment

Preferred integration methods:

- `StyleBoxTexture` where texture-backed surfaces make sense
- `TextureRect` overlays for decorative framing when needed
- existing Godot theme overrides for color/state control
- minimal node changes when a visual wrapper is needed for consistent framing

## 11. Responsive Behavior

The current HUD already adapts to width bands. This pass should preserve that approach.

Responsive goals:

- no overlap between top bar and drawer
- bottom strip remains readable on narrower desktop widths
- cards continue to stack cleanly in drawers and modals
- visual assets scale acceptably without becoming blurry or overly thick

This redesign is desktop-first. It should remain stable on narrower desktop sizes already handled by the project, but does not introduce a new mobile layout mode.

## 12. Out of Scope

- gameplay mechanic changes
- new menus or new game flow
- replacing the overall scene architecture
- rewriting dynamic panel generation logic
- major navigation model changes
- introducing character portraits or cinematic UI sequences in this pass

## 13. Risks and Mitigations

### Risk 1: Visual mismatch across many card scenes

Mitigation:

- define one shared card language first
- apply targeted variants second

### Risk 2: New assets look good in isolation but clash in-game

Mitigation:

- design against the actual star map background and current HUD shell
- validate in the Godot scene, not just as standalone images

### Risk 3: Styling requires too many logic changes

Mitigation:

- prefer scene-level and theme-level integration
- only touch `HudLayer.gd` when a state-specific style hook is necessary

### Risk 4: Overuse of neon harms readability

Mitigation:

- reserve bright highlights for selected, primary, or urgent states only
- keep default surfaces mostly dark and calm

## 14. Testing and Validation

Validation should cover:

- Godot scene loads without missing resources
- HUD remains usable across existing width breakpoints
- selected, hover, pressed, and disabled states remain legible
- drawer and modal content still scroll and align correctly
- fleet tabs and main tabs remain visually and functionally distinct
- resource readability remains strong over the star map background

## 15. Success Criteria

This redesign succeeds if:

- the HUD reads immediately as a premium sci-fi flagship bridge
- the interface feels visually unified across shell and cards
- key controls stand out without excessive glow
- the redesign integrates into existing scenes with low behavioral risk
- the project gains installable in-engine assets, not just concept art
