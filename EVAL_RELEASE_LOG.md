# Eval Release Log

---

## March 3, 2026 — Debug Evals (30 evals)

**Directory:** `DebugEvals/`

Introduced a new eval category focused on **bug-fixing**. Each debug eval takes an existing scenario, injects a bug, and asks the model to resolve it. This tests a fundamentally different skill from code generation: the ability to read existing (broken) code, diagnose the root cause, and apply a targeted fix.

30 debug evals were created from 15 base scenarios, with 1–3 bug variants per scenario. Bugs were created through renaming and relocating instances in the data model, changing property values and constants, inverting logic (swapped operators, inverted conditions), and creating loopholes in player state management.

---

## October 14, 2025 — Code Generation Batch 1 (47 evals)

**Directory:** `Evals/`

Initial release of OpenGameEval with 47 code-generation evals. These evals test an LLM's ability to write Luau scripts that modify or extend Roblox experiences. Tasks range from simple property changes to multi-step game feature implementations, evaluated via automated execution of unit tests.

The evals are heavily engineered towards code generation to implement game mechanics. They present a balance of adjusting scenes, revising existing logic, and building new functionalities.