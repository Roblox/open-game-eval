# Gemini 3 Flash Preview vs Gemini 3.5 Flash — Eval Comparison Report

**Date**: May 19-20, 2026
**Eval suites**: 87 evals (open-game-eval/Evals) + 30 evals (open-game-eval/DebugEvals), k=5 runs each, timeout=300s. Sections 1-11 cover the 87-eval Open Game suite; §12 covers the 30-eval Debug suite.
**Configuration**: Identical request body shape on all runs: identical system prompt, identical tools. 

---

`gemini-3.5-flash` is Google's newest flash model. This 87-eval suite shows **statistically indistinguishable pass rates** between 3.5 flash and 3-flash-preview. The newer 3.5-flash issues **28% more tool calls** and takes **~37% more wall-clock time** (70 min vs 51 min) than the 3-flash-preview baseline on our eval set. The equivalence result is correct in aggregate pass rates but masks substantial per-eval heterogeneity: 3.5-flash is dramatically more verbose and that verbosity alternates between a strength (more thorough multi-step state-setup, better on complex configuration tasks) and a weakness (over-explores when a direct edit would suffice, gets stuck in investigative spirals).

## 1. Summary

### Key Findings

1. **Pass rates are statistically equivalent** — Pass@1 differs by 0.23pp (47.82% → 48.05%, p=0.94), Pass@5 by 2.30pp (60.92% → 63.22%, p=0.53), Cons@5 by 0.19pp (48.84% → 49.03%, p=0.96), All@5 by -1.26pp (35.12% → 33.86%, p=0.75). None reach significance under a paired t-test on n=87 matched evals.

2. **3.5-flash reasons ~4× more per eval than the baseline** — Per-eval reasoning tokens: ~2k (3-flash-preview) vs ~8k (3.5-flash) (paired t-test t=-12.0, p<10⁻¹⁹). With no explicit `thinkingLevel` set and Vertex applying its per-model defaults, 3.5-flash uses roughly 4× the thinking of 3-flash-preview.

3. **3.5-flash uses 28% more tool calls** (9.14 → 11.69, paired t-test p<0.001). Highly significant increases in `execute_luau` +50% (p=0.001), `script_read` +54% (p<0.001), `search_game_tree` +29% (p<0.001), `script_search` +46% (p<0.001), `script_grep` +79% (p=0.002). `multi_edit` (-13%, p=0.27) and `inspect_instance` (-7%, p=0.47) are statistically unchanged.

4. **10 evals improved ≥30pp, 7 regressed ≥30pp** — Improvements (3.5-flash gains over the baseline) cluster on tasks that require flipping a state variable AFTER making cosmetic changes (`080_surburban_school_lights_on`). Regressions (3.5-flash drops vs the baseline) come from 3.5-flash choosing to investigate deeply when 3-flash-preview takes the minimal direct route and lands the right answer.

### Recommendations

The aggregate Pass@1 equivalence is not a uniform parity across tasks: there is considerable per task heterogoeneity and we see the averaged result of a clear tradeoff. 

The newer 3.5-flash spends ~4× more thinking and 28% more tool calls per eval, and that extra investigation pays back on tasks with multiple coordinated state changes or several specific named values to set (§8 Patterns A and B). The same investigation tendency becomes a liability on direct one-object-one-edit tasks, where the baseline's shorter trajectory consistently lands the right answer and 3.5-flash's deeper read of existing structure produces drift or inconsistent solutions (§9 Pattern A). The two directions roughly cancel across the suite — 10 improvements ≥30pp against 7 regressions ≥30pp — which is what produces the indistinguishable aggregate.

The statistical tie should not be interpreted as "the new model is no better" but "the new model traded some simple-task reliability for stronger long-task capability". The practical question becomes which side of that tradeoff a given workload lives on.

- **Prefer `gemini-3.5-flash` for multi-clause / multi-edit tasks** — i.e. prompts that require setting several specific named values on an existing module, or coordinating multiple state changes across multiple instances. This is where 3.5-flash's deeper investigation pays back: it cleared every ≥30pp lasertag/weapon improvement in the suite (`104_lasertag_mobile_camera_recoil`, `107_lasertag_grenade_weapon`, `118_weapon_spawn_and_pickup`, `119_lasertag_add_megablaster`) plus the racing multi-condition reset task (`110_racing_car_offtrack_reset` — see §8 Pattern B), and it catches the non-obvious final state-flip / multi-property setup that the baseline routinely misses (`080_surburban_school_lights_on`, `092_fps_shoot_ground_bounce`, `096_fps_target_overhead_health_ui`). The extra `script_read` / `script_grep` cost converts directly into picking up the second and third clauses of a non-obvious user intent that the baseline silently drops.

- **Prefer `gemini-3-flash-preview` for single-shot direct edits and latency-sensitive flows** — "do one thing to one object" tasks (add a death trap, set a sprint speed, swap a material). This is where the baseline's minimalism is the win and 3.5-flash's investigation impulse turns into a regression (§9 Pattern A), and where 3-flash-preview's ~27% lower wall-clock (51 min vs 70 min on this sweep) is a real latency advantage.

- **Suggestions for 3.5-flash** 
  - **Try lower `thinkingLevel` values** ~4× reasoning-token gap comes from Vertex's per-model auto-allocation under default settings — we send no `thinkingLevel`. Setting an explicit lower `thinkingLevel` on the request should suppress the spiral-into-investigation behavior on simple tasks while preserving the model's ability to plan multi-clause edits.
  - **Add a system-prompt nudge.** A line such as "If the task is a single direct change to a single object, make the edit directly. Only read existing scripts when the prompt names specific values, modules, or behaviors you must preserve or modify" aligns the model's exploration policy with the task class, and matches the cleanest differentiator we observed between the two models in the regression analysis.

---

## 2. Note on Thinking Level

This report's numbers come from runs that leave **`thinkingLevel`** at its default value in the request body. Vertex applies its own per-model auto-thinking allocation to each model independently. The ~4× reasoning-token gap between the older 3-flash-preview baseline and the newer 3.5-flash is therefore an asymmetry in Vertex's per-model auto allocation, not something we control via request flags. It is a property of how the models behave under **default** conditions in this environment.

---

## 3. Overall Pass Rates

| Metric | 3-flash-preview (baseline) | 3.5-flash (newer) | Delta | p-value | Sig |
|--------|------------------|-----------|-------|---------|-----|
| **Pass@1** | 47.82% | 48.05% | **+0.23pp** | 0.943 | — |
| **Pass@5** | 60.92% | 63.22% | **+2.30pp** | 0.530 | — |
| **Cons@5** | 48.84% | 49.03% | **+0.19pp** | 0.959 | — |
| **All@5** | 35.12% | 33.86% | **-1.26pp** | 0.755 | — |

Paired two-sided t-test on per-eval values (n=87 matched evals). Every p-value in this report comes from that same paired t-test. The 0.23pp gap on Pass@1 is comfortably inside sampling noise (t=-0.07, p=0.94).

---

## 4. Token Usage and Wall-Clock

| Metric | 3-flash-preview (baseline) | 3.5-flash (newer) | Δ |
|--------|------------------|-----------|---|
| **Per-eval input tokens (avg)** | ~142k | ~250k | **+76%** |
| **Per-eval output tokens (avg)** | ~3.1k | ~10.9k | **+253%** |
| **Per-eval reasoning tokens (avg)** | ~1.9k | ~7.8k | **+320%** |
| **Wall-clock (full sweep)** | ~51 min | ~70 min | **+37%** |

Wall-clock is measured from sweep start (first request submitted) to sweep end (last result written). The input-token increase reflects 3.5-flash running longer conversations (more turns × ~5-10k tokens of context per turn). The output-token increase reflects more verbose assistant messages between tool calls. The reasoning-token increase is Vertex's per-model auto allocation (see §2).

---

## 5. Tool Usage

Paired t-test on per-eval tool counts (n=87 matched evals).

| Tool | 3-flash-preview (baseline) | 3.5-flash (newer) | Δ | Δ% | p-value | Sig |
|------|------------------|-----------|---|----|---------|----|
| **Total** | **9.14** | **11.69** | **+2.56** | **+28%** | **<0.001** | *** |
| `execute_luau` | 1.83 | 2.75 | +0.92 | +50% | 0.001 | *** |
| `multi_edit` | 1.10 | 0.96 | -0.14 | -13% | 0.267 | — |
| `search_game_tree` | 2.15 | 2.77 | +0.62 | +29% | <0.001 | *** |
| `inspect_instance` | 1.41 | 1.31 | -0.10 | -7% | 0.471 | — |
| `script_grep` | 0.63 | 1.13 | +0.50 | +79% | 0.002 | ** |
| `script_read` | 1.37 | 2.10 | +0.73 | +54% | <0.001 | *** |
| `script_search` | 0.35 | 0.51 | +0.16 | +46% | <0.001 | *** |

3.5-flash steps up on **every investigative tool** (`execute_luau`, `search_game_tree`, `script_read`, `script_search`, `script_grep`) at p≤0.002. `multi_edit` (-13%) and `inspect_instance` (-7%) are the only two tools where the per-eval differences don't reach significance. The paired t-test gains a lot of power on the tool-usage table relative to a naive independent Welch test because per-eval tool counts are strongly correlated across the two models: the same evals demand the same amount of investigation regardless of which model attempts them.


---

## 6. Timeouts

A run "times out" when its subprocess exceeds the 300s budget — the LLM is still emitting turns when the framework cuts it off. We hold this 5-minute cap fixed across every model in this repo and treat it as part of the quality bar: a solution that doesn't arrive within 5 minutes fails the latency expectation for a Roblox Assistant turn regardless of whether the model would have eventually produced a passing answer. Both models hit timeouts, but in different shapes:

| Model | Timeouts | Distinct evals affected |
|-------|----------|--------------------------|
| **3-flash-preview (baseline)** | 22 / 435 (5.1%) | 16 evals (diffuse) |
| **3.5-flash (newer)** | 9 / 435 (2.1%) | 2 evals (`103_city_lights_on_off`, `122_animal_item_with_rarity`) |

**3-flash-preview's timeouts** span 16 different evals, with `103_city_lights_on_off` and `107_lasertag_grenade_weapon` accounting for 3 runs each, `050_surburban_gaspump_explode` and `088_surburban_garage_door_speed_up` for 2 each, and the remaining 12 evals 1 each. Failures are diffuse and individually recoverable (other k's still pass) but harder to predict.

**3.5-flash's timeouts** are concentrated: all 9 hit on just 2 evals — `103_city_lights_on_off` (4 of 5 k) and `122_animal_item_with_rarity` (all 5 k). 

The single eval where both models time out is `103_city_lights_on_off`. Notably, **the older 3-flash-preview baseline actually solves `122_animal_item_with_rarity` (4/5 pass, no timeouts)** where the newer 3.5-flash gets 0/5 due to over investigation and timeout.

---

## 7. Per-Eval Results

### Improvements (3.5-flash Pass@1 gain ≥ 30pp over baseline) — 10 evals

| Eval | Preview P@1 | 3.5 P@1 | Δ | P@5 preview→3.5 | Tools preview→3.5 |
|------|-------------|---------|---|-----------------|-------------------|
| `080_surburban_school_lights_on` | 0% | 80% | +80 | 0%→100% | 22.8→22.0 |
| `119_lasertag_add_megablaster` | 20% | 100% | +80 | 100%→100% | 9.2→19.8 |
| `104_lasertag_mobile_camera_recoil` | 0% | 60% | +60 | 0%→100% | 7.0→11.2 |
| `107_lasertag_grenade_weapon` | 40% | 100% | +60 | 100%→100% | 10.6→27.2 |
| `110_racing_car_offtrack_reset` | 40% | 100% | +60 | 100%→100% | 16.0→29.4 |
| `070_village_make_npc_walk` | 0% | 40% | +40 | 0%→100% | 5.6→14.6 |
| `092_fps_shoot_ground_bounce` | 40% | 80% | +40 | 100%→100% | 10.4→15.6 |
| `118_weapon_spawn_and_pickup` | 0% | 40% | +40 | 0%→100% | 8.0→11.8 |
| `025_chase_and_damage` | 20% | 60% | +40 | 100%→100% | 3.6→3.8 |
| `096_fps_target_overhead_health_ui` | 20% | 60% | +40 | 100%→100% | 6.2→7.4 |

### Regressions (3.5-flash Pass@1 drop ≥ 30pp vs baseline) — 7 evals

| Eval | Preview P@1 | 3.5 P@1 | Δ | P@5 preview→3.5 | Tools preview→3.5 |
|------|-------------|---------|---|-----------------|-------------------|
| `100_obby_add_death_trap` | 100% | 0% | -100 | 100%→0% | 3.8→15.2 |
| `027_firstperson_block` | 100% | 20% | -80 | 100%→100% | 1.6→2.6 |
| `085_platformer_rosphere_hover` | 80% | 0% | -80 | 100%→0% | 7.8→12.6 |
| `122_animal_item_with_rarity` | 80% | 0% | -80 | 100%→0% | 3.4→4.4 |
| `010_left_shift_sprint_5s` | 100% | 40% | -60 | 100%→100% | 2.6→3.0 |
| `075_create_npc_enemy` | 100% | 40% | -60 | 100%→100% | 8.2→18.2 |
| `091_surburban_fix_grass_in_house` | 60% | 20% | -40 | 100%→100% | 14.2→10.4 |

**Stability counts**: 28 evals (32%) are 0% on both models. 17 evals (20%) are 100% on both. The middle 42 evals (48%) carry the divergence captured in the tables above.

---

## 8. Improvement Root Cause Analysis (3.5-flash beats baseline)

### Pattern A: Cosmetic Change Without State Toggle — 3.5-flash Catches the Last Step

The newer 3.5-flash completes all the state-setup steps where the older 3-flash-preview baseline makes the *visible* part of the change but skips the boolean / numeric state flip that the eval check actually queries.

**`080_surburban_school_lights_on`** (0% → 80%, tools 22.8→22.0). The eval walks every room and asserts: (1) `LightsOn` BoolValue is true, (2) Light material is Neon, (3) SpotLight is enabled, (4) LightSwitch orientation is rotated. The framework counts each assert as a separate check.
- **3-flash-preview (baseline)**: 0/5 k pass. **All 5 runs** stop at the same point — they pass Checks 1-3 (set `LightsOn` to true, set Material to Neon, enable SpotLight) but fail Check 4. The baseline consistently does the three visible state changes and consistently omits the one geometric rotation.
- **3.5-flash (newer)**: 4/5 k pass all 4 asserts per room. So 3.5-flash usually but not always physically flips the LightSwitch geometry.


### Pattern B: Tool-Heavy Configuration Tasks (lasertag / weapon / multi-condition)

Five improvements cluster on multi-clause configuration tasks: four lasertag/weapon evals (`104`, `107`, `118`, `119`) plus the racing reset task (`110_racing_car_offtrack_reset`, which asks for a coordinated "detect upside-down OR off-track for 5s → teleport car + player back to start"). All five share some characteristics: the eval requires coordinating multiple state changes or setting several specific named values across an existing module or system. 3.5-flash typically issues 11-30 tool calls per run (`script_read` and `script_grep` to map the existing module before issuing `multi_edit`). The baseline issues 7-16 tool calls and produces edits that satisfy 1-2 of the checks but miss others.

These are exactly the "and-also" tasks where the baseline's minimalism omits the second or third clause of a multi-clause user intent — and where the newer 3.5-flash's deeper investigation justifies its extra cost.


---

## 9. Regression Root Cause Analysis (3.5-flash worse than baseline)

### Pattern A: Over-Investigation Hurts on Direct Tasks

When the task is "do one thing to one object", 3.5-flash's instinct to investigate before acting hurts; the baseline's minimalism wins.

**`100_obby_add_death_trap`** (100% → 0%, tools 3.8→15.2) — the cleanest regression
- **3-flash-preview (baseline)**: 5/5 pass. Issues ~3.8 tool calls per run — a direct edit to add a death trap part, no extensive exploration. The minimalism is the win.
- **3.5-flash (newer)**: 0/5 pass. Issues ~15 tool calls per run (heavy `script_read`/`script_grep`/`execute_luau` probes mapping the existing obby structure) before producing edits that fail the eval check.

**`027_firstperson_block`** (100% → 20%, tools 1.6→2.6) — Both models issue very few tool calls. The baseline consistently produces the script shape that passes; 3.5-flash drifts across runs.

### Pattern B: Drops 100% Evals to 0%

**`122_animal_item_with_rarity`** (80% → 0%, tools 3.4→4.4) — All 5 of 3.5-flash's runs are recorded as timeouts (this eval accounts for 5 of the 9 total 3.5-flash timeouts). The failure mode is identical across all 5 k: the model issues 3-6 exploration tool calls (`search_game_tree`, `inspect_instance`, `script_read`, `execute_luau`), and it does not produce a solution in the allocated time.

### Pattern C: NPC Tasks

**`075_create_npc_enemy`** (100% → 40%, tools 8.2→18.2) — 3.5-flash's tool usage is double the baseline's, but it drops from 100% reliable to 40%. The baseline takes the simpler direct route and hits 100% reliably; 3.5-flash explores existing scripts more heavily and produces inconsistent solutions across runs.

---

## 10. Interpretation

| Dimension | gemini-3-flash-preview (baseline) | gemini-3.5-flash (newer) |
|-----------|------------------|------------------------|
| Exploration depth | Shallower | Deeper (~28% more tool calls) |
| Reasoning tokens (Vertex auto) | ~2k / eval | ~8k / eval |
| Wall-clock per eval | ~35s | ~48s |
| Failure mode | Premature termination, minimal scaffolds, missed state flips | Run-to-run variance on already-passing evals, over-investigation |
| Timeouts | 22 (16 evals, diffuse) | 9 (2 evals) |



---

## 11. Baseline Comparisons: vs GPT-5.5 and Claude Opus 4.7

The same 87-eval suite has been run previously against `gpt-5.5-2026-04-23` and `claude-opus-4-7`.
### Headline Pass Rates (87 evals, 5 runs each, n=435 runs per model)

| Model | Pass@1 | Pass@5 | Cons@5 | All@5 | Tools/eval | Tool err rate |
|---|---|---|---|---|---|---|---|
| `gemini-3-flash-preview` (baseline) | 47.82% | 60.92% | 48.84% | **35.12%** | 9.14 | 5.51% | 
| `gemini-3.5-flash` (newer) | **48.05%** | **63.22%** | **49.03%** | 33.86% | 11.69 | 3.30% | 
| `claude-opus-4-7` | 43.45% | 58.62% | 43.38% | 32.25% | 5.53 | 1.33% |
| `gpt-5.5-2026-04-23` | 40.69% | 56.32% | 40.13% | 30.62% | **4.77** | **0.91%** | 

Both Gemini variants lead the table on Pass@1, beating both non-Gemini baselines. The Gemini-vs-Opus gap is small (~4.5pp, not significant under paired t-test); the Gemini-vs-GPT-5.5 gap is larger (~7pp) and reaches significance on Pass@1 for 3.5-flash (p=0.035) but only borderline for 3-flash-preview (p=0.061). The clearest gap shows up on **Cons@5 vs GPT-5.5**, where both Gemini variants beat GPT by ~9pp at p≤0.040. Both Gemini variants also lead on Pass@5; only on All@5 do they sit within 3pp of Opus (3-flash-preview +2.87pp, 3.5-flash +1.61pp).

All p-values below are from `paired_analysis` (paired t-test on n=87 matched evals).

### Paired Tests — Gemini 3-Flash-Preview (Baseline) vs Other Baselines

| Metric | 3-flash-preview | GPT-5.5 | Δ | p | vs Opus 4.7 | Δ | p |
|---|---|---|---|---|---|---|---|
| Pass@1 | 47.82% | 40.69% | -7.13pp | 0.061 | 43.45% | -4.37pp | 0.317 |
| Pass@5 | 60.92% | 56.32% | -4.60pp | 0.288 | 58.62% | -2.30pp | 0.672 |
| Cons@5 | 48.84% | 40.13% | -8.71pp | **0.040** | 43.38% | -5.46pp | 0.260 |
| All@5  | 35.12% | 30.62% | -4.50pp | 0.309 | 32.25% | -2.88pp | 0.522 |
| Tools/eval | 9.14 | 4.77 | -4.36 (-48%) | **<0.001** | 5.53 | -3.61 (-39%) | **<0.001** |
| Tool err rate | 5.51% | 0.91% | -4.60pp | — | 1.33% | -4.18pp | — |

### Paired Tests — Gemini 3.5-Flash (Newer) vs Other Baselines

| Metric | 3.5-flash | GPT-5.5 | Δ | p | vs Opus 4.7 | Δ | p |
|---|---|---|---|---|---|---|---|
| Pass@1 | 48.05% | 40.69% | -7.36pp | **0.035** | 43.45% | -4.60pp | 0.263 |
| Pass@5 | 63.22% | 56.32% | -6.90pp | 0.134 | 58.62% | -4.60pp | 0.397 |
| Cons@5 | 49.03% | 40.13% | -8.89pp | **0.021** | 43.38% | -5.65pp | 0.215 |
| All@5  | 33.86% | 30.62% | -3.25pp | 0.405 | 32.25% | -1.62pp | 0.716 |
| Tools/eval | 11.69 | 4.77 | -6.92 (-59%) | **<0.001** | 5.53 | -6.17 (-53%) | **<0.001** |
| Tool err rate | 3.30% | 0.91% | -2.39pp | — | 1.33% | -1.97pp | — |

### Cross-Model Patterns

**Both non-Gemini baselines use ~half the tool calls of either Gemini variant** (4.77 GPT, 5.53 Opus vs 9.14 3-flash-preview, 11.69 3.5-flash) at p<0.001 in every paired test. Tool error rates are also higher for Gemini. The takeaway: Gemini reaches its pass rate via more aggressive tool use, with a small but real cost in per-call reliability. Efficient-per-call models like GPT-5.5 and Opus produce tighter and shorter trajectories, perhaps with a cost in their pass rates (see the Opus detailed report for more analysis on Opus 4.7's tendency to under-explore)

**Eval-level concordance, not just aggregate**: 3.5-flash hits 100% on 25 evals; the overlap with Opus-100% is 16 of those 25, and with GPT-5.5-100% is 17 of 25. 3.5-flash scores 0% on 32 evals, overlapping Opus-0% on 23 and GPT-5.5-0% on 27. Models broadly agree on which evals are easy and which are intractable — disagreement concentrates in the middle band.

### Per-Pair Takeaways

**Gemini 3-flash-preview (baseline) vs Opus 4.7.** Pass@1 +4.4pp, Pass@5 +2.3pp, Cons@5 +5.5pp — the older Gemini variant leads on every aggregate metric but none reach significance. The two models reach this band by very different routes: 3-flash-preview issues 9.1 tools/eval with 5.5% raw error rate; Opus issues 5.5 tools/eval with 1.3% error rate (~0.07 errors/eval).

**Gemini 3.5-flash (newer) vs Opus 4.7.** Pass@1 +4.6pp, Pass@5 +4.6pp, Cons@5 +5.7pp — same shape as 3-flash-preview vs Opus, just slightly larger margins on Pass@5. 3.5-flash achieves this with 11.7 tools/eval vs Opus's 5.5 — even more tool-heavy than the older Gemini baseline. 

**vs GPT-5.5 — both Gemini variants lead by ~7pp on Pass@1.** GPT-5.5 has the lowest tool usage (4.77/eval) and the lowest tool error rate (0.91%) of any model in this comparison. Under a paired t-test on n=87 evals: the 3.5-flash vs GPT-5.5 gap reaches significance on Pass@1 (p=0.035) and Cons@5 (p=0.021); the 3-flash-preview vs GPT-5.5 gap is borderline on Pass@1 (p=0.061) and significant on Cons@5 (p=0.040). The Pass@5 gap is not significant for either variant (p=0.13-0.29) — GPT-5.5 nearly closes the gap when given more attempts. GPT-5.5 trades pass rate for sharply lower tool consumption (p<10⁻⁸ on tool count for both variants).

### Bottom Line

On this 87-eval open-game-eval suite, **both Gemini variants lead Pass@1, Pass@5, and Cons@5**, with Opus 4.7 a few points behind (not statistically significant) and GPT-5.5 ~7pp behind (significant on Pass@1 for 3.5-flash p=0.035, borderline for 3-flash-preview p=0.061; significant on Cons@5 for both at p≤0.040). 
---

## 12. Debug Eval Suite (30 evals)


### Pass Rates

Paired t-test on per-eval values (n=30 matched evals).

| Metric | 3-flash-preview (baseline) | 3.5-flash (newer) | Δ | p |
|---|---|---|---|---|
| **Pass@1** | **51.33%** | 49.33% | **-2.00pp** | 0.693 |
| **Pass@5** | 63.33% | **70.00%** | **+6.67pp** | 0.423 |
| **Cons@5** | **51.06%** | 48.46% | **-2.59pp** | 0.577 |
| **All@5** | **43.31%** | 36.33% | **-6.98pp** | 0.383 |

None reach significance with n=30 evals, but the pattern is **consistent and bidirectional**: the older 3-flash-preview baseline leads Pass@1 / Cons@5 / All@5, while the newer 3.5-flash leads Pass@5. 
