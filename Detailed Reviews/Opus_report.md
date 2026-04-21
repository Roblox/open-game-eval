# Claude Opus 4.7 vs 4.6 — Eval Comparison Report

**Date**: April 21, 2026
**Eval suite**: 87 evals (open-game-eval/Evals), k=5 runs each, timeout=300s
**Configuration**: Identical system prompt, identical tools.

---

Opus 4.7 is the first release from a large model provider after we published 40 new evals, so it gets the first detailed treatment.
Plus, there are some interesting patterns between 4.7 vs 4.6 that deserve some explanation.
The apparent 'regression' is there, but is not statistically significant in our eval set.
However, behavior differences in tool calling are very real and significant.

## 1. Summary

### Key Findings

1. **Overall performance gap is not statistically significant** — Pass@1 drops 4.6pp (48.0% → 43.4%, p=0.24), Pass@5 drops just 1.1pp (59.8% → 58.6%, p=0.84). Neither reaches significance. The models are broadly comparable in aggregate.

2. **Opus 4.7 explores dramatically less** — 39% fewer tool calls overall (9.1 → 5.5, p<10⁻¹²). Every exploration tool shows a highly significant drop: `search_game_tree` (-38%, p<10⁻⁷), `script_grep` (-64%, p<10⁻⁸), `script_read` (-55%, p<10⁻⁵), `inspect_instance` (-39%, p=0.007). Core action tools (`multi_edit`, `execute_luau`) are only marginally lower.

3. **16 evals regressed ≥30pp, 9 improved ≥30pp** — Regressions stem from (a) insufficient exploration: 4.7 gives up after 2–3 tree searches instead of probing deeper, and (b) narrow fixes that miss bulk instances. Improvements come from 4.7 choosing simpler, more correct Roblox patterns (proper `HumanoidRootPart` rigs, `multi_edit` over `execute_luau` for persistence, avoiding reparenting that breaks eval checks).


### Recommendations

- **System prompt tuning**: For open-ended tasks requiring discovery (e.g., "remove tutorial assets," "make lights toggle with day/night"), Opus 4.7 benefits from explicit instructions to explore the full workspace structure before acting. Without this, it makes assumptions and stops early.
- **Opus 4.7 strengths**: On well-defined tasks where the target is clear, 4.7 produces cleaner code with correct Roblox idioms (e.g., `Humanoid:MoveTo` over `PathfindingService`, script-based changes over runtime `execute_luau`). It excels when fewer tool calls suffice.

---

## 2. Overall Pass Rates

| Metric | Opus 4.6 | Opus 4.7 | Delta | p-value | Sig |
|--------|----------|----------|-------|---------|-----|
| **Pass@1** | 48.0% | 43.4% | **-4.6pp** | 0.244 | — |
| **Pass@5** | 59.8% | 58.6% | **-1.1pp** | 0.836 | — |
| **Cons@5** | 48.1% | 43.4% | **-4.7pp** | 0.270 | — |
| **All@5** | 38.3% | 32.2% | **-6.1pp** | 0.137 | — |



---

## 3. Tool Usage

| Tool | Opus 4.6 | Opus 4.7 | Δ | Δ% | p-value | Sig |
|------|----------|----------|---|----|---------|----|
| **Total** | **9.12** | **5.53** | **-3.60** | **-39%** | **<10⁻¹²** | *** |
| `search_game_tree` | 2.11 | 1.31 | -0.80 | -38% | <10⁻⁷ | *** |
| `script_grep` | 1.31 | 0.48 | -0.83 | -64% | <10⁻⁸ | *** |
| `script_read` | 1.64 | 0.74 | -0.90 | -55% | <10⁻⁵ | *** |
| `script_search` | 0.39 | 0.18 | -0.22 | -56% | <10⁻⁴ | *** |
| `inspect_instance` | 1.17 | 0.72 | -0.45 | -39% | 0.007 | *** |
| `execute_luau` | 1.52 | 1.19 | -0.33 | -21% | 0.011 | ** |
| `multi_edit` | 0.92 | 0.87 | -0.05 | -5% | 0.402 | — |

Every exploration tool is significantly reduced. `multi_edit` — the primary action tool — is effectively unchanged, confirming the gap is in **information gathering**, not action-taking.

### Tool Error Rates

No significant difference in tool error rates between the two models (total_tool_errors: 0.064 vs 0.074, p=0.71). Marginal increase in `multi_edit` errors for 4.7 (p=0.08), likely from less pre-edit validation.


---

## 4. Per-Eval Results

### Regressions (Pass@1 drop ≥ 30pp) — 16 evals

| Eval | 4.6 P@1 | 4.7 P@1 | Δ | P@5 4.6→4.7 | Tools 4.6→4.7 |
|------|---------|---------|---|-------------|---------------|
| `002_emit_white_smoke` | 100% | 0% | -100 | 100%→— | 7.2→3.0 |
| `049_surburban_fridge_door_open` | 100% | 0% | -100 | 100%→— | 8.0→5.2 |
| `103_city_lights_on_off` | 100% | 0% | -100 | 100%→— | 8.4→6.4 |
| `053_surburban_billboard_change_decal` | 100% | 20% | -80 | 100%→100% | 10.8→5.4 |
| `075_village_remove_tutorial_assets` | 100% | 20% | -80 | 100%→100% | 12.0→2.8 |
| `008_spawn_as_r6` | 100% | 40% | -60 | 100%→100% | 7.4→5.6 |
| `027_firstperson_block` | 100% | 40% | -60 | 100%→100% | 3.0→3.2 |
| `068_village_collectable_plants` | 60% | 0% | -60 | 100%→— | 15.0→7.2 |
| `074_red_grass_sway` | 60% | 0% | -60 | 100%→— | 5.6→8.0 |
| `079_platformer_roblonk_blue_raise` | 80% | 20% | -60 | 100%→100% | 6.6→2.6 |
| `102_city_spawn_on_tallest_building` | 60% | 0% | -60 | 100%→— | 4.0→3.0 |
| `018_weather_machine` | 40% | 0% | -40 | 100%→— | 5.8→3.6 |
| `026_make_traffic_light_v3` | 40% | 0% | -40 | 100%→— | 13.6→3.0 |
| `033_count_coins` | 40% | 0% | -40 | 100%→— | 2.4→2.2 |
| `043_platformer_bouncing_jumper` | 40% | 0% | -40 | 100%→— | 29.6→5.4 |
| `086_racing_car_jump` | 40% | 0% | -40 | 100%→— | 24.8→12.8 |

### Improvements (Pass@1 gain ≥ 30pp) — 9 evals

| Eval | 4.6 P@1 | 4.7 P@1 | Δ | P@5 4.6→4.7 | Tools 4.6→4.7 |
|------|---------|---------|---|-------------|---------------|
| `025_chase_and_damage` | 0% | 100% | +100 | —→100% | 5.0→2.8 |
| `038_platformer_coin_multiple_pickup` | 0% | 80% | +80 | —→100% | 11.2→7.2 |
| `048_surburban_fountain_insert` | 0% | 80% | +80 | —→100% | 6.4→3.4 |
| `099_city_add_cars` | 40% | 100% | +60 | 100%→100% | 7.0→6.4 |
| `088_surburban_garage_door_speed_up` | 0% | 60% | +60 | —→100% | 6.0→5.6 |
| `118_weapon_spawn_and_pickup` | 0% | 60% | +60 | —→100% | 11.4→5.4 |
| `003_make_leaves_fall_colored` | 40% | 80% | +40 | 100%→100% | 4.8→2.6 |
| `100_obby_add_death_trap` | 20% | 60% | +40 | 100%→100% | 9.8→2.8 |
| `106_lasertag_weapon_balance` | 0% | 40% | +40 | —→100% | 12.2→9.4 |

**Stability counts**: 24 evals (28%) are 0% in both runs. 20 evals (23%) are 100% in both runs.

---

## 5. Regression Root Cause Analysis

### Pattern A: Insufficient Exploration (10 of 16 regressions)

Opus 4.7 performs fewer exploration steps, misses critical information, and produces incomplete or wrong solutions. Examples:

**`075_village_remove_tutorial_assets`** (100% → 20%, tools 12→2.8)
- **4.6**: After keyword searches fail, does a **broad `search_game_tree` listing of Workspace** (depth 2) which reveals the `Info NPCs` folder, then removes it with `execute_luau`.
- **4.7**: Does 2 keyword-only `search_game_tree` calls, gets noisy results, concludes there are no tutorial assets, and **stops**. Never lists Workspace structure. `Info NPCs` remains.

**`043_platformer_bouncing_jumper`** (40% → 0%, tools 29.6→5.4)
- **4.6**: Kept digging through `LevelArt`/`Jumps`/templates via `search_game_tree`, `script_grep`, `inspect_instance` until finding `OneJump` parts; renamed them and wrote a bounce handler.
- **4.7**: After `search_game_tree("OneJump")` returned no matches and a broad grep was inconclusive, **asked the user for clarification** instead of exploring deeper. No code written.

**`103_city_lights_on_off`** (100% → 0%, tools 8.4→6.4)
- **4.6**: Deep script + lighting discovery; wrote a controller that **drives `Lighting.ClockTime`** forward (RunService.Heartbeat) plus toggles lights based on time.
- **4.7**: Searched for lights but never traced whether a time-of-day script existed. Wrote a light toggler that **assumes something else advances time**. Game check fails: "Time is not changing."

### Pattern B: Narrow Fix Missing Bulk Instances (3 of 16)

**`049_surburban_fridge_door_open`** (100% → 0%, tools 8.0→5.2)
- **4.6**: Used `execute_luau` to enumerate **all 6** `StoreFridgeDoorScript` instances across doors; bulk-updated `.Source` for each.
- **4.7**: Used `multi_edit` on a **single script path**. Only one of six fridge doors was modified; eval checks all doors.

**`002_emit_white_smoke`** (100% → 0%, tools 7.2→3.0)
- **4.6**: Inspected existing chimney structure, discovered existing `Smoke`/`ParticleEmitter` parts, and **updated their properties** (Rate, Color, etc.).
- **4.7**: Hardcoded three chimney paths, added new `ParticleEmitter` objects, but left existing smoke unchanged. Check says "A chimney was found that did not have white smoke!" — the check inspects existing emitters, not new ones.

### Pattern C: Wrong Approach (3 of 16)

**`074_red_grass_sway`** (60% → 0%, tools 5.6→8.0)
- **4.6**: Short approach — set `workspace.GlobalWind = Vector3.new(25, 0, 25)`. Matches scene check.
- **4.7**: After API errors on `Terrain.Decoration`, pivoted to creating **custom Part-based grass blades with scripted sway animation**. More creative but fails check: "GlobalWind isn't set high enough to be noticeable."

---

## 6. Improvements

### Pattern A: Better Roblox Idioms (5 of 9 improvements)

**`025_chase_and_damage`** (0% → 100%, tools 5.0→2.8)
- **4.6**: Built NPC with `Body` as `PrimaryPart` (no `HumanoidRootPart`), used `PathfindingService` with blocking `MoveToFinished:Wait()` — NPCs failed to reach player.
- **4.7**: Used `HumanoidRootPart` + simple `Humanoid:MoveTo(target)` + `task.wait(0.2)` loop. All 23 checks passed.

**`038_platformer_coin_multiple_pickup`** (0% → 80%, tools 11.2→7.2)
- **4.6**: Set 5-second respawn timer. Eval retries pickup before timer expires — fails.
- **4.7**: Used 1-second per-player cooldown with coins always visible. Second pickup succeeds within test window.

### Pattern B: Stable Hierarchy / Persistent Changes (4 of 9)

**`048_surburban_fountain_insert`** (0% → 80%, tools 6.4→3.4)
- **4.6**: Reparented fountain to `BackDeck` — eval check crashes: `"Fountain is not a valid member of Folder 'Workspace. water fountain spawn'"`.
- **4.7**: Scaled and positioned fountain **without reparenting**. Hierarchy stays intact, all 3 checks pass.

**`088_surburban_garage_door_speed_up`** (0% → 60%, tools 6.0→5.6)
- **4.6**: Used `execute_luau` to set BodyGyro properties at runtime. Eval checks saved script state — fails.
- **4.7**: Used `multi_edit` on the door script source (`P * 2` at init). Change persists in saved state.

---

## 7. Interpretation

The two models are **statistically equivalent in pass rate** on this 87-eval suite with identical configurations. The non-significant 4.6pp gap could close or reverse with a different eval set or more runs.

However, **behavioral divergence is real and large**. Opus 4.7 is a more efficient but less thorough explorer:

| Dimension | Opus 4.6 | Opus 4.7 |
|-----------|----------|----------|
| Exploration depth | Deep, persistent | Shallow, targeted |
| Tool calls per eval | 9.1 | 5.5 |
| Failure mode | Over-engineering, wrong Roblox idioms | Under-exploration, narrow fixes |
| Strength | Open-ended discovery tasks | Well-specified, targeted tasks |

Recommendation for Opus users: Opus 4.7 with an exploration-encouraging system prompt may combine the best of both — lower cost, correct idioms, and sufficient discovery depth.
