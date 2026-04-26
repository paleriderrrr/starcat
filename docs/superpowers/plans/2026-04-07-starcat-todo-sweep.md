# Starcat Todo Sweep Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the four in-scope todos from `docs/design/07_dev_scope_and_progress.md`: remaining text/UI garble cleanup, chapter 05 API alignment, chapter 06 victory regression, and colonization flow integration.

**Architecture:** Keep the current split between FastAPI contract simulation, Godot autoload state, and Godot HUD rendering. Fix the remaining user-facing string corruption in Godot data/autoload files, then align backend/client contracts for war and director APIs, then wire the resulting reports into existing Godot world-data and victory/colonization presentation so one verification pass can cover all todos.

**Tech Stack:** FastAPI, Pydantic, Godot 4.5 GDScript, headless Godot CLI, pytest

---

### Task 1: Lock regression coverage for the documented gaps

**Files:**
- Create: `D:/2Projects/26.03.11 starcat/backend/tests/test_starcat_todos.py`

- [ ] **Step 1: Write failing tests for current known gaps**

Add tests that:
- assert key Godot source/data files no longer contain the known mojibake fragments currently visible in `ApiClient.gd`, `GameState.gd`, and `InitialData.gd`
- assert `/api/fleet/move` returns chapter 05-style strategic move fields
- assert colonization preview/report data includes chapter 4.2.4 confirmation fields

- [ ] **Step 2: Run tests to verify they fail**

Run: `D:\2Projects\26.03.11 starcat\backend\.venv\Scripts\python.exe -m pytest backend\tests\test_starcat_todos.py -q`
Expected: FAIL on mojibake fragments and missing response/report fields.

- [ ] **Step 3: Implement the minimum code to satisfy those failing assertions**

Touch only the files required by the failing tests in Tasks 2-4.

- [ ] **Step 4: Re-run the targeted tests**

Run: `D:\2Projects\26.03.11 starcat\backend\.venv\Scripts\python.exe -m pytest backend\tests\test_starcat_todos.py -q`
Expected: PASS.

### Task 2: Finish remaining text and UI readability cleanup

**Files:**
- Modify: `D:/2Projects/26.03.11 starcat/starcat/scripts/autoload/ApiClient.gd`
- Modify: `D:/2Projects/26.03.11 starcat/starcat/scripts/autoload/GameState.gd`
- Modify: `D:/2Projects/26.03.11 starcat/starcat/scripts/data/InitialData.gd`

- [ ] **Step 1: Replace the remaining mojibake user-facing strings with readable Chinese**

Cover request failure text, owner fallback text, colonization prompt text, building/ship/treaty/mission labels, colony mode labels, faction names, objective strings, and other visible descriptions already proven broken by the failing tests.

- [ ] **Step 2: Keep logic untouched while normalizing presentation strings**

Do not add fallback behavior or change gameplay rules while cleaning text.

### Task 3: Align chapter 05 war/director API contracts

**Files:**
- Modify: `D:/2Projects/26.03.11 starcat/backend/main.py`
- Modify: `D:/2Projects/26.03.11 starcat/starcat/scripts/autoload/ApiClient.gd`
- Modify: `D:/2Projects/26.03.11 starcat/starcat/scripts/autoload/GameState.gd`
- Modify: `D:/2Projects/26.03.11 starcat/starcat/scripts/HudLayer.gd`

- [ ] **Step 1: Expand fleet strategic move response to expose status, ETA, path segments, and warnings**

Keep backward-compatible fields if the Godot side still reads them.

- [ ] **Step 2: Verify combat/director endpoints are fully surfaced through ApiClient**

Route responses into `world_data` report keys instead of dropping them.

- [ ] **Step 3: Show the new war/director reports in the existing HUD report cards**

Reuse the current card scenes instead of creating new UI paradigms.

### Task 4: Complete chapter 06 victory and chapter 4.2.4 colonization integration

**Files:**
- Modify: `D:/2Projects/26.03.11 starcat/starcat/scripts/GameLogic.gd`
- Modify: `D:/2Projects/26.03.11 starcat/starcat/scripts/autoload/GameState.gd`
- Modify: `D:/2Projects/26.03.11 starcat/starcat/scripts/HudLayer.gd`

- [ ] **Step 1: Fill colonization preview/report payload with the documented confirmation fields**

Include one-time cost, estimated turns, initial population, initial stability, opened slots, maintenance, and risk.

- [ ] **Step 2: Re-check victory progress aggregation against chapter 06 presentation needs**

Make sure diplomatic and ascension status summaries expose trigger and settlement data needed by the HUD.

- [ ] **Step 3: Surface colonization and victory details in the existing panel cards**

Use current `StatusCard`, `ColonizationOptionCard`, and report cards rather than introducing new UI structures.

### Task 5: Verify the whole sweep

**Files:**
- Modify: `D:/2Projects/26.03.11 starcat/docs/design/07_dev_scope_and_progress.md`

- [ ] **Step 1: Run targeted backend regression tests**

Run: `D:\2Projects\26.03.11 starcat\backend\.venv\Scripts\python.exe -m pytest backend\tests\test_starcat_todos.py -q`
Expected: PASS.

- [ ] **Step 2: Run the documented Godot headless verification**

Run:
`& "E:\applications\Godot_v4.6.1-stable_win64.exe\Godot_v4.6.1-stable_win64_console.exe" --headless --path "D:\2Projects\26.03.11 starcat\starcat" --quit`

Expected: exit code 0, no script parse errors, no scene instantiation errors.

- [ ] **Step 3: Update the progress table if the verification supports status changes**

Reflect any completed in-scope items in `docs/design/07_dev_scope_and_progress.md`.
