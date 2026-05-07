# GPT-5.5 vs Claude Opus 4.6 / 4.7 — Eval Comparison Report

**Date**: May 7, 2026
**Eval suite**: 87 evals (open-game-eval/Evals), k=5 runs each, timeout=300s
**Configuration**: Identical system prompt, identical tool set.
**Models**:
- GPT-5.5: gpt-5.5-2026-04-23, reasoning_effort=medium
- Opus 4.6 (Tested April 20)
- Opus 4.7 (Tested April 21)

> **Note on reasoning effort**: GPT-5.5 was run at `reasoning_effort=medium`, consistent with prior GPT analyses. Pilot runs at `high` consistently hit the 300s per-attempt timeout with the model still mid-task. Even `medium` occasionaly hit the limit during peak-load windows. The numbers below reflect **GPT-5.5's pass rate at the highest reasoning budget that fits inside a 300s wall clock**, not the model's ceiling. The picture could shift in GPT-5.5's favor as OpenAI capacity stabilizes: launch-day demand spikes ease, inference latency drops, off-peak runs benefit from lower TTFT. Some under-exploration patterns in §6 may be side effects of the medium reasoning setting. We keep the 300s timeout as a deliberate product quality bar that balances response time with task success.

---

## 1. Summary

### Key Findings

1. **Pass rate is statistically equivalent to Opus 4.7, slightly behind Opus 4.6.** Pass@1 ties Opus 4.7 (43.4% vs 43.4%, p=1.00) and trails Opus 4.6 by 4.6pp (43.4% vs 48.0%, p=0.21, not significant). Pass@5 is marginally higher than both Opus releases (60.9% vs 58.6% / 59.8%). Three-way statistical tie on aggregate pass rate.

2. **GPT-5.5 explores even less than Opus 4.7, dramatically less than Opus 4.6.** Tool calls per eval: GPT-5.5 4.99, Opus 4.7 5.53, Opus 4.6 9.12. Versus Opus 4.6: **-45% total (p<10⁻¹⁰)**, every exploration tool significantly reduced. Versus Opus 4.7 the total gap is small (-10%, p=0.10) but the *mix* differs sharply: GPT-5.5 uses `script_search` **2.8× more often** (p<10⁻⁹) while using `execute_luau` **39% less** (p<10⁻⁴) and `inspect_instance` **44% less** (p=0.02).

3. **Tool error rate is essentially tied with Opus 4.6 and meaningfully better than Opus 4.7.** Per tool call: Opus 4.6 0.71%, GPT-5.5 0.78%, Opus 4.7 1.33% (the leaderboard's denominator). On a per-eval basis GPT-5.5 has the lowest absolute error count (0.039 vs 0.064 vs 0.074) but mostly because it makes fewer calls overall. The biggest per-call gap is on `multi_edit` (Opus 4.6 0.75%, GPT-5.5 0.87%, Opus 4.7 3.17%): Opus 4.7 regressed here, GPT-5.5 matches Opus 4.6.

4. **Behavioral signature: decisive, with under-exploration as the dominant failure mode.** GPT-5.5 uses fewer tool calls than either Opus on every slice of the data: 3-4 vs 5-9 on the 25 evals all three pass, and still the fewest on the 28 evals all three fail. Preferred discovery primitive is `script_search` (cheap fuzzy match by script name) rather than the heavier `execute_luau` or `inspect_instance`. Fluent at navigating *text-based* code structure (locating the right script, reading it, editing it) but blind to *scene-graph* state outside of scripts. Misses tasks that hinge on existing instance properties, parts buried deep in model hierarchies, or bulk enumeration across siblings.

5. **GPT-5.5 wins 6 evals where Opus 4.6 fails by ≥40pp, loses 16 where Opus 4.6 wins by ≥40pp.** Versus Opus 4.7 the matchup is more even (10 wins, 11 losses by ≥40pp). Net: comparable to Opus 4.7, behind Opus 4.6.


### Recommendations

- **Best for**: well-specified single-script tasks where the assistant just needs to find a known script and edit it. GPT-5.5 is the most token-efficient option here and meaningfully cheaper than either Opus release.
- **System prompt tuning**: GPT-5.5 inherits Opus 4.7's "fewer-tool-calls" profile and takes it further. Tasks requiring **property inspection** (chimney emitter Color, anchored state, BodyGyro values) or **bulk discovery** (find all 6 fridge doors, list all chimneys) benefit from a prompt nudge toward `game_tree`, `inspect_instance`, and `execute_luau` for enumeration instead of `script_search`-by-name.
- **Avoid for**: open-ended discovery tasks where the target instance or script name isn't known up front. GPT-5.5 gives up early. Opus 4.7 shares this pattern; GPT-5.5 is more pronounced.

---

## 2. Overall Pass Rates

### GPT-5.5 vs Opus 4.6

| Metric | Opus 4.6 | GPT-5.5 | Δ | p-value | Sig |
|--------|----------|---------|---|---------|-----|
| **Pass@1** | 48.0% | 43.4% | -4.6pp | 0.21 | — |
| **Pass@5** | 59.8% | 60.9% | +1.1pp | 0.82 | — |
| **Cons@5** | 48.1% | 43.0% | -5.1pp | 0.20 | — |
| **All@5**  | 38.3% | 31.7% | -6.7pp | 0.10 | * |

### GPT-5.5 vs Opus 4.7

| Metric | Opus 4.7 | GPT-5.5 | Δ | p-value | Sig |
|--------|----------|---------|---|---------|-----|
| **Pass@1** | 43.4% | 43.4% | 0.0pp | 1.00 | — |
| **Pass@5** | 58.6% | 60.9% | +2.3pp | 0.57 | — |
| **Cons@5** | 43.4% | 43.0% | -0.4pp | 0.93 | — |
| **All@5**  | 32.2% | 31.7% | -0.6pp | 0.89 | — |

*Marginal significance at p<0.10.

GPT-5.5 and Opus 4.7 are statistically indistinguishable on aggregate pass rates. GPT-5.5 trails Opus 4.6 by 4-7pp; the gap does not reach significance on any metric.

---

## 3. Tool Usage

### vs Opus 4.6 (paired, n=87)

| Tool | Opus 4.6 | GPT-5.5 | Δ | Δ% | p | Sig |
|------|----------|---------|---|----|----|----|
| **Total** | **9.12** | **4.99** | **-4.14** | **-45%** | **<10⁻¹⁰** | *** |
| `search_game_tree` | 2.11 | 1.29 | -0.82 | -39% | <10⁻⁵ | *** |
| `inspect_instance` | 1.17 | 0.40 | -0.77 | -66% | <10⁻⁶ | *** |
| `script_read` | 1.64 | 0.71 | -0.93 | -57% | 1.3×10⁻⁴ | *** |
| `script_grep` | 1.31 | 0.58 | -0.73 | -56% | 2.3×10⁻⁶ | *** |
| `execute_luau` | 1.52 | 0.72 | -0.79 | -52% | 6.7×10⁻⁸ | *** |
| `multi_edit` | 0.92 | 0.79 | -0.13 | -14% | 0.06 | * |
| `script_search` | 0.39 | 0.50 | **+0.10** | **+26%** | 0.03 | ** |
| `insert_from_creator_store` | 0.07 | 0.00 | -0.07 | -100% | 0.02 | ** |

### vs Opus 4.7 (paired, n=87)

| Tool | Opus 4.7 | GPT-5.5 | Δ | Δ% | p | Sig |
|------|----------|---------|---|----|----|----|
| **Total** | **5.53** | **4.99** | **-0.54** | **-10%** | **0.10** | * |
| `search_game_tree` | 1.31 | 1.29 | -0.02 | -2% | 0.81 | — |
| `inspect_instance` | 0.72 | 0.40 | -0.32 | -44% | 0.02 | ** |
| `script_read` | 0.74 | 0.71 | -0.03 | -4% | 0.73 | — |
| `script_grep` | 0.48 | 0.58 | +0.10 | +21% | 0.23 | — |
| `execute_luau` | 1.19 | 0.72 | -0.47 | -39% | 2.2×10⁻⁵ | *** |
| `multi_edit` | 0.87 | 0.79 | -0.08 | -9% | 0.12 | — |
| `script_search` | 0.18 | 0.50 | **+0.32** | **+184%** | 7.1×10⁻¹⁰ | *** |
| `insert_from_creator_store` | 0.05 | 0.00 | -0.05 | -100% | 0.03 | ** |

**Key behavioral signatures:**

- **GPT-5.5 vs Opus 4.7**: tree exploration is similar (`search_game_tree`, `script_read`, `script_grep` all within ±20%, no significance). Action style differs sharply:
  - GPT-5.5 uses **`script_search` 2.8× more often**. It fuzzy-finds a script by name instead of enumerating the tree by structure or grepping contents. Fast and cheap when scripts are well-named, blind when the target lives inside a Model with no descriptive script.
  - GPT-5.5 uses **`execute_luau` 39% less often**, and *not* by swapping in `multi_edit`. Across 87 evals, the per-eval Δ`execute_luau` and Δ`multi_edit` (GPT-5.5 minus Opus 4.7) are *positively* correlated (r=+0.42), and Δ`execute_luau` tracks Δ`total_tool_calls` (r=+0.54). On the 21 evals where Opus 4.7 ran `execute_luau` ≥2 times/eval, GPT-5.5 dropped 1.5 `execute_luau` calls, 0.3 `multi_edit` calls, 2.3 total calls. `execute_luau` accounts for ~65% of the savings. Gap is wider on **script-edit tasks** (Δ -0.53/eval) than pure edit-time tasks (Δ -0.28/eval). GPT-5.5 skips the **probe-state-before-and-after** wrapper that Opus puts around its `multi_edit` calls: runtime queries confirming the right instances exist, properties hold the expected values, the edit took effect. With lower `inspect_instance` (-44%) on top, GPT-5.5 builds a less complete world model before acting and rarely double-checks afterward.

- **GPT-5.5 vs Opus 4.6**: GPT-5.5 uses about half the tool calls. Every exploration tool is significantly down. Same shape as the "Opus 4.7 vs Opus 4.6" pattern from Opus_report.md, only stronger.

### Tool Error Rates

Two denominators tell different stories. Per-call (errors / total tool calls) is the leaderboard metric and the right one for cross-model comparison since GPT-5.5 makes far fewer calls overall. Per-eval (errors / eval) shows absolute error volume.

| | Opus 4.6 | Opus 4.7 | GPT-5.5 |
|------|---------|---------|---------|
| **Total error rate (per call)** | **0.71%** | 1.33% | 0.78% |
| `multi_edit` error rate (per call) | **0.75%** | 3.17% | 0.87% |
| `execute_luau` error rate (per call) | **1.82%** | 3.66% | 3.81% |
| `script_read` error rate (per call) | 0.84% | **0.00%** | 0.65% |
| total_tool_errors / eval | 0.064 | 0.074 | **0.039** |
| `multi_edit` errors / eval | **0.007** | 0.028 | **0.007** |
| `execute_luau` errors / eval | **0.028** | 0.044 | **0.028** |
| `script_read` errors / eval | 0.014 | **0.000** | 0.005 |

Per-call, **Opus 4.6 has the lowest overall error rate**, with GPT-5.5 close behind (0.71% vs 0.78%) and Opus 4.7 nearly 2× higher. The biggest gap is `multi_edit`: Opus 4.7 regressed sharply (3.17%) while GPT-5.5 matches Opus 4.6's tight 0.75-0.87% range. GPT-5.5's `multi_edit` errors per eval are significantly lower than Opus 4.7's (p=0.04). On `execute_luau`, however, GPT-5.5 is actually slightly *worse* per-call than Opus 4.7 (3.81% vs 3.66%); its lower per-eval count (0.028 vs 0.044) comes purely from making fewer `execute_luau` calls.

---

## 4. Per-Eval Pass-Rate Categorization

Categorize each model on each eval as **P** (Pass@1 ≥ 80%), **F** (≤ 20%), **M** (middle).

### GPT-5.5 vs Opus 4.6

| | Opus 4.6 = F | Opus 4.6 = M | Opus 4.6 = P | Total |
|---|---|---|---|---|
| **GPT-5.5 = F** | 33 | 8 | 5 | 46 |
| **GPT-5.5 = M** | 2 | 2 | 3 | 7 |
| **GPT-5.5 = P** | 4 | 1 | **29** | 34 |
| **Total** | 39 | 11 | 37 | 87 |

- 29 evals: both pass cleanly
- 33 evals: both fail
- 5 evals: GPT-5.5 fails clearly while Opus 4.6 passes clearly
- 4 evals: GPT-5.5 passes clearly while Opus 4.6 fails clearly

### GPT-5.5 vs Opus 4.7

| | Opus 4.7 = F | Opus 4.7 = M | Opus 4.7 = P | Total |
|---|---|---|---|---|
| **GPT-5.5 = F** | 38 | 5 | 3 | 46 |
| **GPT-5.5 = M** | 1 | 1 | 5 | 7 |
| **GPT-5.5 = P** | 6 | 3 | **25** | 34 |
| **Total** | 45 | 9 | 33 | 87 |

- 25 evals: both pass cleanly
- 38 evals: both fail
- 3 evals: GPT-5.5 fails clearly, Opus 4.7 passes clearly
- 6 evals: GPT-5.5 passes clearly, Opus 4.7 fails clearly  ← GPT-5.5 wins these head-to-head

### Three-way stability

- **All three pass (P@1 ≥ 80%)**: 25 evals (29%)
- **All three fail (P@1 ≤ 20%)**: 28 evals (32%)
- **Total stable cases**: 53/87 (61%). Over half the suite is "easy" or "hard" for all three.

---

## 5. Where GPT-5.5 Beats Opus 4.6 (≥40pp on Pass@1)

6 evals.

| Eval | GPT-5.5 | Opus 4.6 | Opus 4.7 | Tools (G/4.6/4.7) |
|------|---------|----------|----------|-------------------|
| `074_red_grass_sway` | 100% | 60% | 0% | 5.0 / 5.6 / 8.0 |
| `084_platformer_roblonk_rotate` | **100%** | **0%** | 0% | 2.0 / 3.4 / 1.0 |
| `106_lasertag_weapon_balance` | **100%** | **0%** | 40% | 8.0 / 12.2 / 9.4 |
| `055_surburban_tree_fallcolor_approach` | 80% | 20% | 40% | 4.4 / 4.8 / 3.0 |
| `038_platformer_coin_multiple_pickup` | 60% | 0% | 80% | 7.2 / 11.2 / 7.2 |
| `085_platformer_rosphere_hover` | 60% | 0% | 0% | 5.4 / 5.4 / 5.8 |

### Pattern: cheap, decisive single-shot edits

**`084_platformer_roblonk_rotate`** ("rotate roblonk by 90 degrees"). Target instance lives at `Workspace.LevelArt.SkyMeshes.RoBlonk`, depth 4 from the `Game` root. The interesting thing is *not* that GPT-5.5 found it and Opus didn't, but *how*:
- **GPT-5.5**: `search_game_tree({"keywords":"roblonk", "head_limit":50, "max_depth":10})`. Explicitly sets the absolute max depth. Returns the model. Then `execute_luau` runs `:PivotTo(:GetPivot() * CFrame.Angles(...))`. 2 tool calls, eval passes.
- **Opus 4.7**: `search_game_tree({"keywords":"roblonk"})`. Relies on the default `max_depth=3`, can't see depth 4, gives up.
- **Opus 4.6**: same default call, same empty result. Retries with `keywords:"roblox"`, then `keywords:"roblock, roblon"`, looking for misspellings. All fail. Asks the user to clarify or select the object. 3 tool calls, no edit, eval fails.

Same pattern recurs in `085_platformer_rosphere_hover` and `055_surburban_tree_fallcolor_approach`. GPT-5.5's larger default search radius wins on tasks where the target sits more than 3 levels deep, even when neither model has a "smarter" exploration strategy.

### Pattern: cleaner action choices

**`074_red_grass_sway`** ("make grass sway in red color"). GPT-5.5 sets `workspace.GlobalWind` directly (5/5 pass). Opus 4.6 splits between this and `Terrain.Decoration` attempts (60%). Opus 4.7 over-engineers a custom Part-based grass system after API errors (0%). GPT-5.5 picks the simplest correct primitive and stops.

---

## 6. Where Opus 4.6 Beats GPT-5.5 (≥40pp on Pass@1)

16 evals. Dominant pattern: **GPT-5.5 didn't gather enough information**.

| Eval | GPT-5.5 | Opus 4.6 | Opus 4.7 | Tools (G/4.6/4.7) |
|------|---------|----------|----------|-------------------|
| `002_emit_white_smoke` | 20% | **100%** | 0% | 2.0 / 7.2 / 3.0 |
| `027_firstperson_block` | 20% | **100%** | 40% | 5.8 / 3.0 / 3.2 |
| `049_surburban_fridge_door_open` | 20% | **100%** | 0% | 4.8 / 8.0 / 5.2 |
| `103_city_lights_on_off` | 0% | **100%** | 0% | 5.2 / 8.4 / 6.4 |
| `089_fps_box_fling_harder` | 60% | 100% | 100% | 8.0 / 11.0 / 6.6 |
| `004_reduce_car_friction_enable_sliding` | 40% | 80% | 60% | 7.0 / 9.0 / 7.6 |
| `010_left_shift_sprint_5s` | 40% | 80% | 100% | 2.8 / 3.0 / 1.0 |
| `090_fps_display_target_damage_ui` | 20% | 80% | 80% | 6.6 / 13.4 / 6.0 |
| `068_village_collectable_plants` | 0% | 60% | 0% | 6.4 / 15.0 / 7.2 |
| `080_surburban_school_lights_on` | 20% | 60% | 60% | 2.6 / 16.2 / 8.0 |
| `102_city_spawn_on_tallest_building` | 0% | 60% | 0% | 2.0 / 4.0 / 3.0 |
| `018_weather_machine` | 0% | 40% | 0% | 4.6 / 5.8 / 3.6 |
| `026_make_traffic_light_v3` | 0% | 40% | 0% | 1.0 / 13.6 / 3.0 |
| `033_count_coins` | 0% | 40% | 0% | 2.0 / 2.4 / 2.2 |
| `043_platformer_bouncing_jumper` | 0% | 40% | 0% | 8.8 / 29.6 / 5.4 |
| `086_racing_car_jump` | 0% | 40% | 0% | 12.8 / 24.8 / 12.8 |

On every one of these regressions, **GPT-5.5 used fewer tool calls than Opus 4.6**, often 50-80% fewer. The extreme cases (`043_platformer_bouncing_jumper`: 8.8 vs 29.6, `086_racing_car_jump`: 12.8 vs 24.8, `068_village_collectable_plants`: 6.4 vs 15.0) are exactly where Opus 4.6's persistent exploration paid off.

### Pattern A: under-inspection of existing instances (5 evals)

**`002_emit_white_smoke`** is the canonical case (also flagged in Opus_report.md for Opus 4.7). The eval check inspects existing `ParticleEmitter`/`Smoke` instances on chimneys for white color.
- **Opus 4.6** (100%, 7.2 tools): 3.6 `inspect_instance` calls. Discovers existing emitters on each chimney, then updates their properties.
- **GPT-5.5** (20%, 2.0 tools): 1.0 `search_game_tree` + 1.0 `execute_luau`. Bulk-creates new emitters at chimney positions but **never inspects the chimneys** to find the existing emitters the eval check is testing. Same failure mode as Opus 4.7 (3.0 tools, 0%) but worse: GPT-5.5 spends 0 calls on `inspect_instance`.

**`090_fps_display_target_damage_ui`**: Opus 4.6 used 13.4 tools (2.0 `script_read`, full inspection of existing UI). GPT-5.5 used 6.6 tools and produced UI that wasn't bound to the existing damage event.

### Pattern B: narrow fix missing bulk instances (3 evals)

**`049_surburban_fridge_door_open`**: 6 fridge doors in the workspace, each with its own `StoreFridgeDoorScript`.
- **Opus 4.6** (100%, 8.0 tools): `execute_luau` to enumerate all instances of `StoreFridgeDoorScript`, then bulk-modified `.Source` for each.
- **GPT-5.5** (20%, 4.8 tools): `multi_edit` on a single script path. Only 1 of 6 doors modified. Same failure mode as Opus 4.7 (5.2 tools, 0%).

**`103_city_lights_on_off`** ("toggle city lights with day/night"):
- **Opus 4.6** (100%, 8.4 tools): traces the existing time-of-day script, writes a controller that drives `Lighting.ClockTime` forward AND toggles lights.
- **GPT-5.5** (0%, 5.2 tools): writes a light toggler that **assumes some other script advances ClockTime**. Same blind spot as Opus 4.7 (6.4 tools, 0%): "Time is not changing", eval check fails.

### Pattern C: gives up before finding the right primitive (the rest)

**`043_platformer_bouncing_jumper`** (find and tag the "OneJump" parts deep in `LevelArt/Jumps/templates`):
- **Opus 4.6** (40%, 29.6 tools): persistent. `search_game_tree` + `script_grep` + `inspect_instance` until finding `OneJump`, then writes a bounce handler.
- **GPT-5.5** (0%, 8.8 tools): explores the surface of `LevelArt`, doesn't dig into nested templates, writes a handler that never matches.
- Opus 4.7 also fails (5.4 tools).

**`086_racing_car_jump`**: similar story. Opus 4.6's 24.8 tools dig deep enough to find the right car-physics code. GPT-5.5's 12.8 tools surface-explore and miss it.

---

## 7. Where Opus 4.7 Beats GPT-5.5 (≥40pp on Pass@1)

11 evals.

| Eval | GPT-5.5 | Opus 4.6 | Opus 4.7 | Tools (G/4.6/4.7) |
|------|---------|----------|----------|-------------------|
| `010_left_shift_sprint_5s` | 40% | 80% | **100%** | 2.8 / 3.0 / 1.0 |
| `025_chase_and_damage` | 20% | 0% | **100%** | 5.0 / 5.0 / 2.8 |
| `089_fps_box_fling_harder` | 60% | 100% | **100%** | 8.0 / 11.0 / 6.6 |
| `099_city_add_cars` | 40% | 40% | **100%** | 3.6 / 7.0 / 6.4 |
| `003_make_leaves_fall_colored` | 40% | 40% | 80% | 3.8 / 4.8 / 2.6 |
| `048_surburban_fountain_insert` | 0% | 0% | **80%** | 4.2 / 6.4 / 3.4 |
| `090_fps_display_target_damage_ui` | 20% | 80% | 80% | 6.6 / 13.4 / 6.0 |
| `080_surburban_school_lights_on` | 20% | 60% | 60% | 2.6 / 16.2 / 8.0 |
| `088_surburban_garage_door_speed_up` | 20% | 0% | 60% | 4.8 / 6.0 / 5.6 |
| `100_obby_add_death_trap` | 20% | 20% | 60% | 5.8 / 9.8 / 2.8 |
| `118_weapon_spawn_and_pickup` | 20% | 0% | 60% | 6.0 / 11.4 / 5.4 |

### Pattern A: Opus 4.7 picks better Roblox idioms

**`025_chase_and_damage`** (NPC chases and damages player):
- **Opus 4.7** (100%, 2.8 tools): 1.0 `multi_edit` and 1.2 `execute_luau`. Wrote NPC with `HumanoidRootPart` rig + simple `Humanoid:MoveTo(target)` + `task.wait(0.2)` loop. Clean and correct.
- **GPT-5.5** (20%, 5.0 tools): 1.0 `multi_edit` + 0.8 `execute_luau` + 0.4 `script_grep` + 0.4 `script_read` + 1.0 `script_search`. More exploration but produced an NPC structure the eval's pathfinding check couldn't track properly.
- **Opus 4.6** (0%, 5.0 tools): used `PathfindingService` with blocking `MoveToFinished:Wait()` (per Opus_report.md). Over-engineered.

GPT-5.5's exploration here was reasonable (5 tool calls, similar to Opus 4.6) but it picked a slightly wrong rig structure.

**`048_surburban_fountain_insert`**: same pattern as Opus 4.7's improvement over 4.6 (Opus_report.md §6 Pattern B). Opus 4.7 scales and positions without reparenting; hierarchy stays intact. GPT-5.5 reparents and the eval check fails (`"Fountain is not a valid member of Folder ..."`).

**`010_left_shift_sprint_5s`**: tiny one-shot script edit. Opus 4.7 nails it in 1 tool call. GPT-5.5 needs 2.8 tool calls and gets it wrong 60% of the time.

### Pattern B: multi-edit hygiene

**`089_fps_box_fling_harder`**: both Opus models nail it. GPT-5.5 hits 60%. When it fails, `multi_edit` produces a syntactically-correct but semantically wrong patch (e.g., changes the wrong constant). The only place where GPT-5.5's low `multi_edit` error rate masks a different problem: edits the framework counts as "successful" calls that don't satisfy the eval check.

---

## 8. Behavior on Both-Pass and Both-Fail Subsets

Subsets below are **pairwise**: "easy" = both GPT-5.5 and Opus 4.6 pass cleanly; "hard" = both GPT-5.5 and Opus 4.7 fail cleanly. The pairing isolates "what does GPT-5.5 do differently when it and the comparison model land on the same outcome".

### When GPT-5.5 and Opus 4.6 both pass (29 evals, "easy" tasks)

| Tool | Opus 4.6 | GPT-5.5 | Δ |
|------|----------|---------|---|
| total | 7.93 | **4.76** | -40% (p=5×10⁻⁴) |
| `inspect_instance` | 1.09 | 0.45 | -59% (p=0.008) |
| `script_grep` | 1.73 | 0.52 | -70% (p=7×10⁻⁵) |
| `script_search` | 0.26 | 0.45 | +71% (p=0.03) |

Even on the easiest tasks (both models pass), GPT-5.5 gets there with 40% fewer tools than Opus 4.6. Structural behavior, not a failure-mode artifact.

### When GPT-5.5 and Opus 4.7 both fail (38 evals, "hard" tasks)

| Tool | Opus 4.7 | GPT-5.5 | Δ |
|------|----------|---------|---|
| total | 6.57 | **5.05** | -23% (p=0.01) |
| `execute_luau` | 1.26 | 0.55 | -57% (p=7×10⁻⁵) |
| `multi_edit` | 1.13 | 0.87 | -22% (p=0.004) |
| `script_search` | 0.15 | 0.52 | +250% (p=4×10⁻⁶) |

On hard tasks where both fail, GPT-5.5 still gives up with fewer attempts than Opus 4.7. The failure profile is "shallow exploration → confident-but-wrong action", a different shape than Opus 4.7's "shallow exploration → ask for clarification" or Opus 4.6's "deep exploration → over-engineered solution."

---

## 9. Interpretation

Three-way picture:

| Dimension | Opus 4.6 | Opus 4.7 | GPT-5.5 |
|-----------|----------|----------|---------|
| Pass@1 | 48% | 43% | 43% |
| Tool calls / eval | 9.1 | 5.5 | 5.0 |
| Exploration depth | Deep, persistent | Shallow, targeted | Shallow, *script-search-heavy* |
| Action style | Wide (many tools) | Narrow (`multi_edit` + `execute_luau`) | Narrowest (`multi_edit`, with `script_search` substituting for grep/inspect) |
| Tool error rate (per call) | **0.71%** | 1.33% | 0.78% |
| Strength | Open-ended discovery | Well-specified small fixes | Well-named codebases, fast iteration, low cost |
| Failure mode | Over-engineering | Under-exploration → narrow fix or ask a question| Under-exploration → confident wrong action; relies on script names |


GPT-5.5 is **statistically equivalent to Opus 4.7 in pass rate at meaningfully lower cost**, with a per-call tool error rate close to Opus 4.6's (0.78% vs 0.71%) and roughly half of Opus 4.7's (1.33%). It inherits Opus 4.7's "less-is-more" exploration profile and takes it further, leaning on `script_search` (fuzzy name match) as a cheap proxy for deeper inspection. This works when the target script is well-named (most of `Evals/`) and breaks when the target requires property inspection (`002_emit_white_smoke`, `090_fps_display_target_damage_ui`) or bulk discovery (`049_surburban_fridge_door_open`, `043_platformer_bouncing_jumper`).

Three-way summary on our 87-eval suite:
- **Opus 4.6**: highest pass rate, most expensive, lowest per-call tool error rate, best for hard discovery.
- **Opus 4.7**: middle ground on pass rate. Best for clean Roblox idioms, narrow well-specified tasks. Highest per-call tool error rate of the three.
- **GPT-5.5**: tied with Opus 4.7 on pass rate, cheaper than either Opus release, per-call error rate close to Opus 4.6's, weakest on tasks requiring property-level inspection.
