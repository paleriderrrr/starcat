# Starcat HUD Bridge UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Install a cold-bridge, anime-realistic sci-fi visual pass across the main HUD shell and major reusable UI cards without changing core gameplay flow.

**Architecture:** Keep the existing `Main -> StarMap + HudLayer` structure, replace flat style boxes with a small shared texture-backed asset family, and retune the current Godot Control scene layout rather than rebuilding it. Most work lives in shared `.tscn` UI scenes and `HudLayer.tscn`, with only small state-aware styling hooks added to `HudLayer.gd` and a regression test update to guard the new asset integration.

**Tech Stack:** Godot 4.6 scenes (`.tscn`), GDScript, local bitmap UI assets, Python `unittest` regression checks

---

## File Structure

### Create

- `starcat/assets/ui/bridge/`
- `starcat/assets/ui/bridge/README.md`
- `starcat/assets/ui/bridge/button_base.png`
- `starcat/assets/ui/bridge/button_hover.png`
- `starcat/assets/ui/bridge/button_pressed.png`
- `starcat/assets/ui/bridge/button_disabled.png`
- `starcat/assets/ui/bridge/chip_panel.png`
- `starcat/assets/ui/bridge/panel_shell.png`
- `starcat/assets/ui/bridge/panel_shell_strong.png`
- `starcat/assets/ui/bridge/card_shell.png`
- `starcat/assets/ui/bridge/card_shell_alert.png`
- `starcat/assets/ui/bridge/tab_active.png`
- `starcat/assets/ui/bridge/tab_idle.png`
- `starcat/assets/ui/bridge/divider_glow.png`

### Modify

- `starcat/scenes/HudLayer.tscn`
- `starcat/scenes/ui/ActionButton.tscn`
- `starcat/scenes/ui/Chip.tscn`
- `starcat/scenes/ui/SectionTitle.tscn`
- `starcat/scenes/ui/SummaryCard.tscn`
- `starcat/scenes/ui/StatusCard.tscn`
- `starcat/scenes/ui/InfoCard.tscn`
- `starcat/scenes/ui/FeedCard.tscn`
- `starcat/scenes/ui/TechCard.tscn`
- `starcat/scenes/ui/BuildingCard.tscn`
- `starcat/scenes/ui/QueueItemCard.tscn`
- `starcat/scenes/ui/FleetShipCard.tscn`
- `starcat/scenes/ui/RouteCard.tscn`
- `starcat/scenes/ui/PostureCard.tscn`
- `starcat/scenes/ui/ProposalCard.tscn`
- `starcat/scenes/ui/ColonizationOptionCard.tscn`
- `starcat/scenes/ui/DiplomacyFactionCard.tscn`
- `starcat/scenes/ui/ApiReportCard.tscn`
- `starcat/scenes/ui/TrendCard.tscn`
- `starcat/scripts/HudLayer.gd`
- `tests/test_godot_backend_migration.py`

## Task 1: Baseline Validation And Asset Landing Zone

**Files:**
- Create: `starcat/assets/ui/bridge/README.md`
- Test: `tests/test_godot_backend_migration.py`

- [ ] **Step 1: Run the current regression suite before any UI edits**

Run:

```powershell
python -m unittest tests.test_godot_backend_migration -v
```

Expected:

```text
... ok
----------------------------------------------------------------------
Ran <existing count> tests in <n.nn>s

OK
```

- [ ] **Step 2: Create the bridge asset directory and document the intended file set**

Create `starcat/assets/ui/bridge/README.md` with:

```markdown
# Bridge UI Asset Pack

This folder contains the shared bitmap surfaces for the Starcat cold-bridge HUD pass.

Files in this pack are reused by:

- `starcat/scenes/HudLayer.tscn`
- `starcat/scenes/ui/ActionButton.tscn`
- `starcat/scenes/ui/Chip.tscn`
- the major card scenes under `starcat/scenes/ui/`

Visual rules:

- dark navy / steel surfaces by default
- cyan-highlight interaction states
- alert red reserved for hostile or warning cards
- textures should stay clean, thin-lined, and readable over the star map
```

- [ ] **Step 3: Verify the new folder is visible to the repo and isolated from gameplay logic**

Run:

```powershell
Get-ChildItem starcat/assets/ui/bridge
```

Expected:

```text
README.md
```

- [ ] **Step 4: Commit the asset landing zone**

Run:

```powershell
git add starcat/assets/ui/bridge/README.md
git commit -m "chore: add bridge ui asset directory"
```

Expected:

```text
[main <sha>] chore: add bridge ui asset directory
 1 file changed, <n> insertions(+)
```

## Task 2: Generate And Install Shared Surface Assets

**Files:**
- Create: `starcat/assets/ui/bridge/button_base.png`
- Create: `starcat/assets/ui/bridge/button_hover.png`
- Create: `starcat/assets/ui/bridge/button_pressed.png`
- Create: `starcat/assets/ui/bridge/button_disabled.png`
- Create: `starcat/assets/ui/bridge/chip_panel.png`
- Create: `starcat/assets/ui/bridge/panel_shell.png`
- Create: `starcat/assets/ui/bridge/panel_shell_strong.png`
- Create: `starcat/assets/ui/bridge/card_shell.png`
- Create: `starcat/assets/ui/bridge/card_shell_alert.png`
- Create: `starcat/assets/ui/bridge/tab_active.png`
- Create: `starcat/assets/ui/bridge/tab_idle.png`
- Create: `starcat/assets/ui/bridge/divider_glow.png`

- [ ] **Step 1: Generate the shared button and panel textures**

Create the asset pack with these concrete targets:

```text
button_base.png          512x192  dark smoked-glass button with cyan edge seam
button_hover.png         512x192  brighter cyan rim and slightly lifted center glow
button_pressed.png       512x192  compact, brighter active fill with strong edge light
button_disabled.png      512x192  low-contrast desaturated navy surface
chip_panel.png           640x256  embedded instrumentation chip with subtle top linework
panel_shell.png          1024x1024 general panel shell for cards and modal bodies
panel_shell_strong.png   1024x1024 heavier framed shell for drawer/modal containers
card_shell.png           1024x768  standard card shell with thin metallic frame
card_shell_alert.png     1024x768  same shell with restrained red alert accent
tab_active.png           512x192  active command tab with cyan-violet highlight
tab_idle.png             512x192  idle command tab with dark metal finish
divider_glow.png         1024x64   thin luminous separator line
```

- [ ] **Step 2: Confirm the generated files are present before scene integration**

Run:

```powershell
Get-ChildItem starcat/assets/ui/bridge | Select-Object Name
```

Expected:

```text
README.md
button_base.png
button_hover.png
button_pressed.png
button_disabled.png
chip_panel.png
panel_shell.png
panel_shell_strong.png
card_shell.png
card_shell_alert.png
tab_active.png
tab_idle.png
divider_glow.png
```

- [ ] **Step 3: Open the files once to trigger Godot import metadata on next editor load**

Run:

```powershell
Get-Item starcat/assets/ui/bridge/*.png | Select-Object Name,Length
```

Expected:

```text
Name                 Length
----                 ------
button_base.png      <non-zero>
...
```

- [ ] **Step 4: Commit the shared texture pack**

Run:

```powershell
git add starcat/assets/ui/bridge
git commit -m "feat: add bridge hud texture pack"
```

Expected:

```text
[main <sha>] feat: add bridge hud texture pack
 <n> files changed, <n> insertions(+)
```

## Task 3: Restyle Shared Controls And Reusable Cards

**Files:**
- Modify: `starcat/scenes/ui/ActionButton.tscn`
- Modify: `starcat/scenes/ui/Chip.tscn`
- Modify: `starcat/scenes/ui/SectionTitle.tscn`
- Modify: `starcat/scenes/ui/SummaryCard.tscn`
- Modify: `starcat/scenes/ui/StatusCard.tscn`
- Modify: `starcat/scenes/ui/InfoCard.tscn`
- Modify: `starcat/scenes/ui/FeedCard.tscn`
- Modify: `starcat/scenes/ui/TechCard.tscn`
- Modify: `starcat/scenes/ui/BuildingCard.tscn`
- Modify: `starcat/scenes/ui/QueueItemCard.tscn`
- Modify: `starcat/scenes/ui/FleetShipCard.tscn`
- Modify: `starcat/scenes/ui/RouteCard.tscn`
- Modify: `starcat/scenes/ui/PostureCard.tscn`
- Modify: `starcat/scenes/ui/ProposalCard.tscn`
- Modify: `starcat/scenes/ui/ColonizationOptionCard.tscn`
- Modify: `starcat/scenes/ui/DiplomacyFactionCard.tscn`
- Modify: `starcat/scenes/ui/ApiReportCard.tscn`
- Modify: `starcat/scenes/ui/TrendCard.tscn`

- [ ] **Step 1: Replace `ActionButton.tscn` flat styles with texture-backed button states**

Update the scene so the button state styles point at the bridge assets:

```tscn
[ext_resource type="Texture2D" path="res://assets/ui/bridge/button_base.png" id="1_base"]
[ext_resource type="Texture2D" path="res://assets/ui/bridge/button_hover.png" id="2_hover"]
[ext_resource type="Texture2D" path="res://assets/ui/bridge/button_pressed.png" id="3_pressed"]
[ext_resource type="Texture2D" path="res://assets/ui/bridge/button_disabled.png" id="4_disabled"]

[sub_resource type="StyleBoxTexture" id="1"]
texture = ExtResource("1_base")
texture_margin_left = 36.0
texture_margin_top = 36.0
texture_margin_right = 36.0
texture_margin_bottom = 36.0

[node name="ActionButton" type="Button"]
theme_override_styles/normal = SubResource("1")
theme_override_colors/font_color = Color(0.92, 0.97, 1, 1)
```

- [ ] **Step 2: Replace `Chip.tscn` with an instrumentation-chip surface**

Update the panel and label treatment:

```tscn
[ext_resource type="Texture2D" path="res://assets/ui/bridge/chip_panel.png" id="1_chip"]

[sub_resource type="StyleBoxTexture" id="1"]
texture = ExtResource("1_chip")
texture_margin_left = 40.0
texture_margin_top = 40.0
texture_margin_right = 40.0
texture_margin_bottom = 40.0

[node name="Chip" type="PanelContainer"]
theme_override_styles/panel = SubResource("1")

[node name="Title" type="Label" parent="Content"]
theme_override_colors/font_color = Color(0.48, 0.82, 0.95, 1)

[node name="Value" type="Label" parent="Content"]
theme_override_font_sizes/font_size = 22
```

- [ ] **Step 3: Unify the major card scenes around the bridge shell**

For each major card scene, add texture-backed panels and consistent text colors using either `card_shell.png` or `card_shell_alert.png`. The standard content block should converge on this shape:

```tscn
[ext_resource type="Texture2D" path="res://assets/ui/bridge/card_shell.png" id="1_card"]

[sub_resource type="StyleBoxTexture" id="1"]
texture = ExtResource("1_card")
texture_margin_left = 44.0
texture_margin_top = 44.0
texture_margin_right = 44.0
texture_margin_bottom = 44.0

[node name="CardRoot" type="PanelContainer"]
theme_override_styles/panel = SubResource("1")

[node name="Title" type="Label" parent="Content"]
theme_override_colors/font_color = Color(0.92, 0.97, 1, 1)

[node name="Meta" type="Label" parent="Content"]
theme_override_colors/font_color = Color(0.53, 0.72, 0.84, 1)
```

Use `card_shell_alert.png` specifically on scenes that present threat, conflict, or warning framing such as `FeedCard.tscn` and `ProposalCard.tscn` when the visual structure supports it.

- [ ] **Step 4: Verify the updated scenes reference the new bridge assets**

Run:

```powershell
Get-ChildItem starcat/scenes/ui/*.tscn | Select-String -Pattern "assets/ui/bridge"
```

Expected:

```text
starcat/scenes/ui/ActionButton.tscn:... assets/ui/bridge/button_base.png
starcat/scenes/ui/Chip.tscn:... assets/ui/bridge/chip_panel.png
starcat/scenes/ui/StatusCard.tscn:... assets/ui/bridge/card_shell.png
...
```

- [ ] **Step 5: Commit the shared scene restyle**

Run:

```powershell
git add starcat/scenes/ui
git commit -m "feat: restyle shared hud cards and controls"
```

Expected:

```text
[main <sha>] feat: restyle shared hud cards and controls
 <n> files changed, <n> insertions(+), <n> deletions(-)
```

## Task 4: Integrate The New Bridge Shell Into `HudLayer`

**Files:**
- Modify: `starcat/scenes/HudLayer.tscn`
- Modify: `starcat/scripts/HudLayer.gd`

- [ ] **Step 1: Reframe the HUD shell containers in `HudLayer.tscn`**

Replace the current flat drawer/modal panel style with texture-backed panel shells and tune offsets conservatively:

```tscn
[ext_resource type="Texture2D" path="res://assets/ui/bridge/panel_shell_strong.png" id="4_shell_strong"]
[ext_resource type="Texture2D" path="res://assets/ui/bridge/panel_shell.png" id="5_shell"]
[ext_resource type="Texture2D" path="res://assets/ui/bridge/divider_glow.png" id="6_divider"]

[sub_resource type="StyleBoxTexture" id="1"]
texture = ExtResource("4_shell_strong")
texture_margin_left = 56.0
texture_margin_top = 56.0
texture_margin_right = 56.0
texture_margin_bottom = 56.0

[node name="TopBar" type="HBoxContainer" parent="Root"]
offset_top = 18.0
offset_bottom = 92.0
theme_override_constants/separation = 8

[node name="RightDrawer" type="PanelContainer" parent="Root"]
offset_left = -468.0
offset_right = -20.0

[node name="BottomTabs" type="HBoxContainer" parent="Root"]
offset_top = -80.0
offset_bottom = -20.0
```

- [ ] **Step 2: Add minimal state-aware style helpers in `HudLayer.gd` for active tabs and fleet buttons**

Keep the current logic, but point style overrides toward the new palette:

```gdscript
func _configure_tab_button(button: Button, active: bool) -> void:
	button.button_pressed = active
	if active:
		var active_style: StyleBoxFlat = _button_style(Color("7AD9FF"), Color("B7F0FF"), 16)
		var active_hover_style: StyleBoxFlat = _button_style(Color("93E3FF"), Color("D8F8FF"), 16)
		var active_pressed_style: StyleBoxFlat = _button_style(Color("5CB6E8"), Color("9FE9FF"), 16)
		button.add_theme_color_override("font_color", Color("071019"))
		button.add_theme_stylebox_override("normal", active_style)
		button.add_theme_stylebox_override("hover", active_hover_style)
		button.add_theme_stylebox_override("pressed", active_pressed_style)
		button.add_theme_stylebox_override("focus", active_hover_style)
	else:
		button.remove_theme_stylebox_override("normal")
		button.remove_theme_stylebox_override("hover")
		button.remove_theme_stylebox_override("pressed")
		button.remove_theme_stylebox_override("focus")
		button.remove_theme_color_override("font_color")
```

Also update the fleet selected-state styling in `_rebuild_bottom_tabs()` to use the same cool-cyan bridge highlight instead of the current pastel purple block.

- [ ] **Step 3: Preserve responsive behavior while tightening shell proportions**

Update `_update_responsive_layout()` with conservative values only:

```gdscript
var drawer_width: float = clampf(viewport_width * (0.30 if narrow_desktop else 0.28), 352.0, 456.0)
var side_margin: float = 20.0 if not compact else 12.0 if very_narrow else 16.0
bottom_tabs.offset_top = -80.0 if not compact else -72.0 if very_narrow else -76.0
bottom_tabs.offset_bottom = -20.0 if not compact else -14.0 if very_narrow else -18.0
toggle_labels_button.custom_minimum_size = Vector2(124 if very_narrow else 136 if narrow_desktop else 148 if compact else 164, 52 if very_narrow else 56)
```

Keep the existing branch structure and anchor logic intact. Do not change the modal interaction model or selection flow.

- [ ] **Step 4: Verify shell styling references and layout hooks**

Run:

```powershell
Select-String -Path starcat/scenes/HudLayer.tscn -Pattern "assets/ui/bridge|panel_shell|divider_glow"
Select-String -Path starcat/scripts/HudLayer.gd -Pattern "_configure_tab_button|drawer_width|toggle_labels_button.custom_minimum_size"
```

Expected:

```text
starcat/scenes/HudLayer.tscn:... assets/ui/bridge/panel_shell_strong.png
starcat/scripts/HudLayer.gd:... func _configure_tab_button(button: Button, active: bool) -> void:
...
```

- [ ] **Step 5: Commit the HUD shell integration**

Run:

```powershell
git add starcat/scenes/HudLayer.tscn starcat/scripts/HudLayer.gd
git commit -m "feat: install bridge shell styling on hud layer"
```

Expected:

```text
[main <sha>] feat: install bridge shell styling on hud layer
 <n> files changed, <n> insertions(+), <n> deletions(-)
```

## Task 5: Add Regression Coverage For The New UI Asset Integration

**Files:**
- Modify: `tests/test_godot_backend_migration.py`

- [ ] **Step 1: Add a test that guards the bridge asset pack and key scene references**

Append this test to `GodotBackendMigrationTests`:

```python
    def test_bridge_ui_assets_are_installed_into_hud_shell_and_shared_controls(self) -> None:
        expected_assets = [
            "starcat/assets/ui/bridge/button_base.png",
            "starcat/assets/ui/bridge/button_hover.png",
            "starcat/assets/ui/bridge/button_pressed.png",
            "starcat/assets/ui/bridge/button_disabled.png",
            "starcat/assets/ui/bridge/chip_panel.png",
            "starcat/assets/ui/bridge/panel_shell.png",
            "starcat/assets/ui/bridge/panel_shell_strong.png",
            "starcat/assets/ui/bridge/card_shell.png",
            "starcat/assets/ui/bridge/tab_active.png",
            "starcat/assets/ui/bridge/tab_idle.png",
            "starcat/assets/ui/bridge/divider_glow.png",
        ]

        for relative_path in expected_assets:
            self.assertTrue((ROOT / relative_path).exists(), relative_path)

        action_button_scene = _read_text("starcat/scenes/ui/ActionButton.tscn")
        chip_scene = _read_text("starcat/scenes/ui/Chip.tscn")
        hud_scene = _read_text("starcat/scenes/HudLayer.tscn")

        self.assertIn("assets/ui/bridge/button_base.png", action_button_scene)
        self.assertIn("assets/ui/bridge/chip_panel.png", chip_scene)
        self.assertIn("assets/ui/bridge/panel_shell_strong.png", hud_scene)
```

- [ ] **Step 2: Run the focused regression test and verify it passes**

Run:

```powershell
python -m unittest tests.test_godot_backend_migration.GodotBackendMigrationTests.test_bridge_ui_assets_are_installed_into_hud_shell_and_shared_controls -v
```

Expected:

```text
test_bridge_ui_assets_are_installed_into_hud_shell_and_shared_controls ... ok
```

- [ ] **Step 3: Run the full regression suite again**

Run:

```powershell
python -m unittest tests.test_godot_backend_migration -v
```

Expected:

```text
... ok
----------------------------------------------------------------------
Ran <updated count> tests in <n.nn>s

OK
```

- [ ] **Step 4: Commit the regression coverage**

Run:

```powershell
git add tests/test_godot_backend_migration.py
git commit -m "test: cover bridge hud asset integration"
```

Expected:

```text
[main <sha>] test: cover bridge hud asset integration
 1 file changed, <n> insertions(+)
```

## Task 6: In-Engine Validation And Final Review

**Files:**
- Modify: any files from Tasks 2-5 only if validation reveals layout or readability regressions

- [ ] **Step 1: Open the Godot project and inspect the updated HUD visually**

Run:

```powershell
godot4 --path starcat --editor
```

If `godot4` is not on PATH, use the local Godot 4.6 executable already used for this project.

Validate:

```text
Top bar reads as one bridge status beam
Right drawer feels heavier and clearer than the old flat panel
Bottom tabs remain readable and active state is obvious
Major cards share one family without looking identical
Neon accents appear on focus, selected, or urgent states only
```

- [ ] **Step 2: Run the project once and confirm the HUD remains interactive**

Run:

```powershell
godot4 --path starcat
```

Validate:

```text
Main scene loads
Top resource chips remain readable over the star map
Selecting a system still opens the right drawer
Selecting fleets still renders fleet tabs and command cards
Bottom tabs still open the center modal
```

- [ ] **Step 3: Make only the smallest scene/script adjustments required by validation**

If a follow-up correction is needed, constrain it to:

```text
spacing or offset tuning in `starcat/scenes/HudLayer.tscn`
size tuning in `starcat/scripts/HudLayer.gd`
text contrast or panel asset assignment in shared `starcat/scenes/ui/*.tscn`
```

Do not introduce new interaction logic, new tabs, or unrelated layout changes during this cleanup step.

- [ ] **Step 4: Commit the validated UI pass**

Run:

```powershell
git add starcat/assets/ui/bridge starcat/scenes/HudLayer.tscn starcat/scenes/ui starcat/scripts/HudLayer.gd tests/test_godot_backend_migration.py
git commit -m "feat: apply bridge ui pass to starcat hud"
```

Expected:

```text
[main <sha>] feat: apply bridge ui pass to starcat hud
 <n> files changed, <n> insertions(+), <n> deletions(-)
```

## Self-Review

Spec coverage check:

- visual direction is implemented through the shared texture pack and shell restyle in Tasks 2-4
- conservative rearrangement is enforced by limiting layout changes to proportional tuning in Task 4
- main HUD shell coverage is addressed in `HudLayer.tscn` and `HudLayer.gd`
- major reusable cards are covered in Task 3
- in-engine installability is covered by Tasks 2, 4, and 6
- regression protection is covered in Task 5

Placeholder scan:

- no `TODO`, `TBD`, or deferred placeholders remain
- every task names exact files and concrete commands

Type and naming consistency:

- asset paths consistently use `res://assets/ui/bridge/...`
- HUD shell references consistently use `panel_shell` / `panel_shell_strong`
- regression test names match the intended asset integration scope
