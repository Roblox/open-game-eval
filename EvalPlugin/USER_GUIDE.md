# Eval Runner Plugin — User Guide

## What Is This?

The Eval Runner plugin lets you write and test **eval files** directly in Roblox Studio. An eval file defines:

1. A **prompt** (what the AI assistant would be asked to do)
2. A **reference solution** (the correct implementation)
3. **Check functions** (assertions that verify the solution is correct)

You write the reference solution and the checks, then click **Run** to validate that your reference passes all checks — including edit-mode scene checks and play-mode runtime checks, all in one click.

---

## Installation

1. You will receive an `EvalRunner.rbxm` file.
2. Place it in your Studio plugins folder (or click **Plugins > Plugins Folder** in Studio to open the correct directory):
   - **Mac:** `~/Documents/Roblox/Plugins/`
   - **Windows:** `%LOCALAPPDATA%\Roblox\Plugins\`
3. Restart Roblox Studio (or open a new session).
4. You should see an **"Eval Runner"** button in the **Plugins** tab of the ribbon.

---

## Quick Start

1. Open the place file your eval targets (e.g., `baseplate.rbxl`, `racing.rbxl`).
2. In the Explorer, create a **Folder** named `Evals` inside `ServerStorage` (the plugin creates it automatically if missing).
3. Inside `ServerStorage.Evals`, create a **ModuleScript**. Name it something descriptive (e.g., `make_part_red`).
4. Paste the eval template (see below) and fill in your prompt, reference, and checks.
5. Click the **"Eval Runner"** button in the Plugins tab to open the panel.
6. Click **Refresh** to discover your eval.
7. Click **Run** next to your eval.
8. The plugin runs edit-mode checks, then automatically starts play mode for runtime checks (if any), then shows combined results.

---

## Eval File Template

Every eval ModuleScript should return a table with this structure:

```lua
local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local utils_checks = require(LoadedCode.EvalUtils.utils_checks)
local utils_runs = require(LoadedCode.EvalUtils.utils_runs)

local expect = utils_checks.expect

local eval: types.BaseEval = {
    prompt = {
        "make a red kill brick that damages the player on touch",
        "create a red part that kills players when they step on it",
    },

    place = "baseplate.rbxl",
    includeAssets = {},
    expected_tool_calls = {},
}

eval.setup = function()
    -- Clean up any leftover kill brick from previous runs
    local old = workspace:FindFirstChild("KillBrick")
    if old then old:Destroy() end

    -- Place kill brick far from default spawn point
    local part = Instance.new("Part")
    part.Name = "KillBrick"
    part.Size = Vector3.new(10, 1, 10)
    part.Position = Vector3.new(50, 1, 50)
    part.Anchored = true
    part.Parent = workspace
end

eval.reference = function()
    local part = workspace:FindFirstChild("KillBrick")
    part.BrickColor = BrickColor.new("Really red")

    local script = Instance.new("Script")
    script.Name = "KillScript"
    script.Source = [[
        local part = script.Parent
        part.Touched:Connect(function(hit)
            local humanoid = hit.Parent:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end)
    ]]
    script.Parent = part
end

-- Edit-mode checks: verify the scene after reference() runs
eval.check_scene = function()
    local part = workspace:FindFirstChild("KillBrick")
    expect(part ~= nil, "KillBrick should exist")
    expect(
        part and part.BrickColor == BrickColor.new("Really red"),
        "KillBrick should be red"
    )
    expect(part and part.Anchored == true, "KillBrick should be anchored")

    local killScript = part and part:FindFirstChild("KillScript")
    expect(killScript ~= nil, "KillScript should exist inside KillBrick")
    expect(
        killScript and killScript:IsA("Script"),
        "KillScript should be a Script"
    )
    expect(
        killScript and string.find(killScript.Source, "Touched"),
        "KillScript should use Touched event"
    )
    expect(
        killScript and string.find(killScript.Source, "Health"),
        "KillScript should modify Health"
    )
end

-- Play-mode checks: run automatically during Play Solo
eval.runConfig = {
    serverCheck = function(_logService, _actions, _evalStorage)
        local part = workspace:FindFirstChild("KillBrick")
        expect(part ~= nil, "[server] KillBrick should exist at runtime")

        local killScript = part and part:FindFirstChild("KillScript")
        expect(killScript ~= nil, "[server] KillScript should exist at runtime")
    end,

    clientChecks = {
        function(_logService, _actions, _evalStorage)
            local Players = game:GetService("Players")
            local player = Players.LocalPlayer
            expect(player ~= nil, "[client] LocalPlayer should exist")

            local character = player and player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            expect(humanoid ~= nil, "[client] Should have a Humanoid")

            local healthBefore = humanoid and humanoid.Health or 0
            expect(healthBefore > 0, "[client] Player should be alive initially")

            -- Teleport the character onto the kill brick
            local killBrick = workspace:FindFirstChild("KillBrick")
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            if hrp and killBrick then
                hrp.CFrame = CFrame.new(killBrick.Position + Vector3.new(0, 3, 0))
            end
            task.wait(2)

            local healthAfter = humanoid and humanoid.Health or 0
            expect(healthAfter < healthBefore, "[client] Player should have taken damage from KillBrick")
        end,
    },
}

return eval
```

### Multi-Client Example

This example tests a coin collection system with two players. The plugin **automatically starts a multi-player test** with 2 clients because `clientChecks` has 2 entries.

```lua
local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local utils_checks = require(LoadedCode.EvalUtils.utils_checks)
local utils_runs = require(LoadedCode.EvalUtils.utils_runs)

local expect = utils_checks.expect

local eval: types.BaseEval = {
    prompt = {
        "make coins that give points when collected, each player tracks their own score",
        "create a coin pickup system with per-player score tracking",
    },

    place = "baseplate.rbxl",
    tags = {},
}

eval.setup = function()
    -- Clean up from previous runs
    for _, child in workspace:GetChildren() do
        if child.Name:match("^Coin_") then child:Destroy() end
    end

    -- Place coins in a line, away from default spawn
    for i = 1, 5 do
        local coin = Instance.new("Part")
        coin.Name = "Coin_" .. i
        coin.Shape = Enum.PartType.Cylinder
        coin.Size = Vector3.new(0.2, 2, 2)
        coin.Position = Vector3.new(40 + i * 4, 1, 40)
        coin.Anchored = true
        coin.BrickColor = BrickColor.new("Bright yellow")
        coin.Parent = workspace
    end
end

eval.reference = function()
    local script = Instance.new("Script")
    script.Name = "CoinSystem"
    script.Source = [[
        local Players = game:GetService("Players")

        Players.PlayerAdded:Connect(function(player)
            local leaderstats = Instance.new("Folder")
            leaderstats.Name = "leaderstats"
            leaderstats.Parent = player

            local score = Instance.new("IntValue")
            score.Name = "Score"
            score.Value = 0
            score.Parent = leaderstats
        end)

        for _, coin in workspace:GetChildren() do
            if coin.Name:match("^Coin_") then
                coin.Touched:Connect(function(hit)
                    local player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
                    if player then
                        local score = player:FindFirstChild("leaderstats")
                            and player.leaderstats:FindFirstChild("Score")
                        if score then
                            score.Value += 1
                        end
                    end
                end)
            end
        end
    ]]
    script.Parent = game:GetService("ServerScriptService")
end

eval.check_scene = function()
    local coinCount = 0
    for _, child in workspace:GetChildren() do
        if child.Name:match("^Coin_") then coinCount += 1 end
    end
    expect(coinCount == 5, "Should have 5 coins, found " .. coinCount)

    local sys = game:GetService("ServerScriptService"):FindFirstChild("CoinSystem")
    expect(sys ~= nil, "CoinSystem script should exist in ServerScriptService")
    expect(sys and string.find(sys.Source, "leaderstats"), "CoinSystem should create leaderstats")
    expect(sys and string.find(sys.Source, "Score"), "CoinSystem should track Score")
end

-- 2 clientChecks → plugin auto-starts multiplayer test with 2 simulated clients
eval.runConfig = {
    serverCheck = function(_logService, _actions, _evalStorage)
        local coinCount = 0
        for _, child in workspace:GetChildren() do
            if child.Name:match("^Coin_") then coinCount += 1 end
        end
        expect(coinCount >= 1, "[server] At least 1 coin should exist at runtime")
    end,

    clientChecks = {
        -- Client 1: walk into coins and verify score increases
        function(_logService, _actions, _evalStorage)
            local player = game:GetService("Players").LocalPlayer
            expect(player ~= nil, "[client 1] LocalPlayer should exist")

            local leaderstats = player and player:WaitForChild("leaderstats", 5)
            expect(leaderstats ~= nil, "[client 1] Should have leaderstats")

            local score = leaderstats and leaderstats:FindFirstChild("Score")
            expect(score ~= nil, "[client 1] Should have a Score value")
            expect(score and score.Value == 0, "[client 1] Score should start at 0")

            -- Teleport onto the first coin to trigger collection
            local character = player.Character
            local hrp = character and character:FindFirstChild("HumanoidRootPart")
            local coin1 = workspace:FindFirstChild("Coin_1")
            if hrp and coin1 then
                hrp.CFrame = CFrame.new(coin1.Position + Vector3.new(0, 3, 0))
            end
            task.wait(1)

            local scoreAfterFirst = score and score.Value or 0
            expect(scoreAfterFirst >= 1, "[client 1] Score should be >= 1 after first coin, got " .. scoreAfterFirst)

            -- Walk through remaining coins using VirtualInput
            -- Coins are spaced 4 studs apart along X axis
            utils_runs.sendKeyEvent(true, Enum.KeyCode.D)
            task.wait(3)
            utils_runs.sendKeyEvent(false, Enum.KeyCode.D)
            task.wait(1)

            local scoreFinal = score and score.Value or 0
            expect(scoreFinal >= 2, "[client 1] Score should be >= 2 after walking through coins, got " .. scoreFinal)
        end,

        -- Client 2: verify independent score (should still be 0 without touching coins)
        function(_logService, _actions, _evalStorage)
            local player = game:GetService("Players").LocalPlayer
            expect(player ~= nil, "[client 2] LocalPlayer should exist")

            local leaderstats = player and player:WaitForChild("leaderstats", 5)
            expect(leaderstats ~= nil, "[client 2] Should have leaderstats")

            local score = leaderstats and leaderstats:FindFirstChild("Score")
            expect(score ~= nil, "[client 2] Should have a Score value")

            -- Client 2 stays at spawn — should not have collected any coins
            task.wait(3)
            local scoreVal = score and score.Value or -1
            expect(scoreVal == 0, "[client 2] Score should remain 0 without touching coins, got " .. scoreVal)
        end,
    },
}

return eval
```

**How multi-client works:**
The plugin counts `#clientChecks`. If there are 2+ entries, it uses `StudioTestService:ExecuteMultiplayerTestAsync(N)` to launch a server + N simulated clients. Each client is assigned an index and runs `clientChecks[index]`. The server collects all client results, then returns everything to the plugin. This all happens automatically when you click **Run** — no manual Test tab interaction needed.

---

## Eval File Fields Reference

| Field | Type | Description |
|-------|------|-------------|
| `prompt` | `{ string }` | A list of prompt variations describing what the AI assistant would be asked. Not executed by the plugin, but required as part of the eval definition. Write 3-5 natural-language variations. |
| `place` | `string` | Which place file this eval is designed for (e.g., `"racing.rbxl"`). Informational — you need to open this place manually before running. |
| `setup` | `function(evalStorage?)` | Runs before `reference()`. Use it to create starter objects, set initial properties, or prepare the scene. |
| `reference` | `function(evalStorage?)` | Your ground-truth implementation. The code that *should* make all checks pass. This is the main thing you write as an annotator. |
| `check_scene` | `function` or `{ function }` | One or more assertion functions that verify the scene after `reference()` runs. This is where you write your "unit tests". |
| `check_game` | `function` or `{ function }` | (Deprecated) Runtime behavior checks. Newer evals should run through serverCheck and clientChecks. |
| `runConfig` | `{ serverCheck, clientChecks }` | Play-mode checks. `serverCheck` runs on the server; `clientChecks` is an array where each function runs on its own simulated client. `#clientChecks` determines the number of clients launched. |
| `includeAssets` | `{ string }` | Asset files the eval needs (e.g., `"Tree.rbxm"`). You must insert these into the place manually. |
| `expected_tool_calls` | `{ string }` | Which tools the assistant is expected to use. Not relevant for reference testing. |

---

## Using the Plugin

### Panel Layout

**Top half — Eval List:**
- Shows all ModuleScripts found under `ServerStorage.Evals`.
- Each row shows the eval name, status indicators, and a **Run** button.
- Warnings appear if an eval is missing `reference` or `check_scene`.
- After running, the status column shows `passes/total` in green (all passed) or red (some failed).

**Bottom half — Result Detail:**
- Click an eval row to see its detailed results.
- Each check is listed with `+` (pass) or `-` (fail) and its message.
- Server and client play-mode results are listed with `[server]` / `[client:N]` prefixes.

### Buttons

| Button | What it does |
|--------|-------------|
| **Run** (per row) | Run all checks for a single eval: `setup()` → `reference()` → `check_scene()` → play-mode checks (auto-starts and auto-stops play mode). |
| **Reset** | Undo all scene changes made by the last eval's `setup()`, `reference()`, and checks. |
| **Refresh** | Re-scan `ServerStorage.Evals` for ModuleScripts. Use after adding/removing evals. |
| **Export** | Copy all results as JSON to your clipboard. |

### What Happens When You Click Run

1. **Edit-mode phase:** The plugin runs `setup()` → `reference()` → `check_scene()` and records pass/fail.
2. **Play-mode phase (automatic):** If the eval defines `check_game`, `serverCheck`, or `clientChecks`:
   - Scripts are injected into the DataModel.
   - Play mode starts automatically via `StudioTestService`.
   - For 1 client check: starts Play Solo.
   - For 2+ client checks: starts a multiplayer test with that many clients.
   - Server runs `check_game` + `serverCheck`, waits for all clients.
   - Each client runs its `clientChecks[index]` and reports back.
   - Play mode stops automatically when all checks complete.
3. **Results merged:** Edit-mode and play-mode results are combined and displayed.

### Workflow Tips

- **One-click testing:** Click Run and wait. No need to manually press F5 — play mode is managed automatically.
- **Iterate fast:** Edit your eval's source, then click Run again. No need to Refresh unless you added/removed ModuleScripts.
- **Check the Output window:** The plugin prints per-check pass/fail details with `[EvalRunner]` prefix.
- **Scene cleanup:** Each Run undoes the previous eval's changes first. Use Reset to manually undo.

---

## Interpreting Results

| Term | Meaning |
|------|---------|
| **checks** | Total number of `expect()` / `assert()` calls that ran (edit + play mode combined). |
| **passes** | How many returned true. |
| **fails** | How many returned false. |
| **interruptions** | Checks that caused an `assert` failure and stopped execution of that check group. |
| **error** | A Lua runtime error in `setup()`, `reference()`, or a check function. |

### Common Issues

| Symptom | Likely Cause |
|---------|-------------|
| "Eval has no reference() function" | You forgot to define `eval.reference`. |
| "LoadedCode not found" | Plugin failed to inject EvalUtils. Try restarting Studio. |
| "StudioTestService" error | Play-mode checks failed to start. Check if another test session is already running. |
| All checks pass but you expected a failure | Double-check your `expect()` conditions — the logic might be inverted. |
| Error in `setup()` | Your setup code references objects that don't exist in the current place. |

---

## Limitations

- **Up to 8 clients.** `StudioTestService:ExecuteMultiplayerTestAsync` supports at most 8 simulated clients per test.
- **Assets** (`includeAssets`) must be manually inserted into the place. The plugin does not auto-import `.rbxm` files.
- **No assistant invocation.** The plugin runs your reference solution only — it does not invoke the Roblox AI Assistant.
- **Module caching.** The plugin bypasses Roblox's `require()` cache, so edits are reflected immediately. Click **Refresh** only when adding/removing eval ModuleScripts.

---

## Viewing the Plugin Source Code

You can inspect every line of the plugin directly in Studio:

1. In the Explorer panel, scroll down to find the **EvalRunner** script (under the plugin's folder).
2. Expand it to see all child ModuleScripts.
3. Double-click any script to open it in the Script Editor.

The source is also available in the repository at `studio_driven_eval/plugin/src/`.

---

## Plugin Source Code Reference

The plugin is a single Script (`init.server.lua`) with four ModuleScript children and a folder of bundled utilities.

### `init.server.lua` — Entry Point

The main plugin script. On load it:

1. **Injects EvalUtils** — clones bundled modules into `game.LoadedCode.EvalUtils.*` so eval files can use the standard `require(LoadedCode.EvalUtils.utils_checks)` pattern.
2. **Creates `ServerStorage.Evals`** if missing.
3. **Sets up UI** — toolbar button ("Eval Runner" in the Plugins tab) and a `DockWidgetPluginGui` panel via `UIBuilder`.
4. **Wires up callbacks** — Run, Refresh, Export, Reset, eval selection.
5. **Run callback** — calls `EvalRunner.run()` for edit-mode checks, then `PlayModeRunner.execute()` for play-mode checks. Merges results and prints a summary to the Output window.
6. **Cleans up on unload** — removes injected `LoadedCode.EvalUtils` and any play-mode runner scripts.

### `EvalDiscovery.lua` — Finding Evals

Scans `ServerStorage.Evals` for ModuleScripts. For each one, it clones the module (to bypass `require()` cache), loads it, and reads metadata:

- `hasReference`, `hasCheckScene`, `hasCheckGame`, `hasSetup`, `hasRunConfig`
- `promptCount` — number of prompt variations

Returns a sorted list used to populate the UI.

### `EvalRunner.lua` — Edit-Mode Checks

The core execution engine for edit-mode testing:

1. **Snapshots containers** — records all instances in `Workspace`, `ServerScriptService`, `ServerStorage`, `ReplicatedStorage`, `Lighting`, `StarterPlayer`, `StarterGui`, `StarterPack`, `SoundService`, and `Teams` *before* the eval runs.
2. **Clones and requires** the eval ModuleScript (bypasses `require()` cache).
3. **Installs a `callTool` shim** — handles `utils_runs.callTool("execute_luau", {code = "..."})` via `loadstring()`.
4. **Runs `setup()` → `reference()` → `check_scene()`** in sequence with `pcall` error handling.
5. **Wraps `expect()`** to capture per-check pass/fail details for the UI.
6. **`undoPreviousRun()`** — compares current container contents against the snapshot and destroys any instance that wasn't present before the eval ran. This is how the **Reset** button works — it removes only eval-created instances without touching manual edits.

### `PlayModeRunner.lua` — Play-Mode Checks

Handles runtime checks using `StudioTestService` for automated play-mode testing:

1. **`hasPlayModeChecks(eval)`** — returns `true` if the eval has `check_game`, `serverCheck`, or `clientChecks`.

2. **`inject(evalInfo, clientCount)`** — prepares the edit DataModel for a play-mode test:
   - **Replicates `LoadedCode`** into `ReplicatedStorage` by rebuilding the folder with fresh `ModuleScript` instances (not `Clone()`, which can fail on already-required modules). This ensures client DataModels in multi-client tests can access EvalUtils.
   - Creates a **`RemoteEvent`** (`_EvalRunnerResultEvent`) and **`RemoteFunction`** (`_EvalRunnerAssignIndex`) in `ReplicatedStorage` for server-client coordination.
   - Injects a **`Script`** into `ServerScriptService` that: sets up the `RemoteFunction` handler to assign client indexes, runs `check_game` + `serverCheck`, waits for all client results via `RemoteEvent`, then calls `StudioTestService:EndTest()` with combined JSON results.
   - Injects a **`LocalScript`** into `StarterPlayerScripts` that: copies `LoadedCode` from `ReplicatedStorage` to `game` root (for module compatibility), waits for the character to be fully alive, gets its assigned index from the server, overrides `utils_runs.sendKeyEvent`/`sendMouseButtonClick` with the non-privileged `VirtualInput` API (`UserInputService:CreateVirtualInput()`), runs `clientChecks[myIndex]`, and fires results back to the server.
   - Clones the **eval module** into `ReplicatedStorage` as `_EvalRunnerModule` so client scripts can `require()` it.
   - All injected instances are tagged with `_EvalRunnerPlayMode` for cleanup.

3. **`execute(evalInfo)`** — the main entry point:
   - Determines client count from `#eval.runConfig.clientChecks`.
   - Calls `inject()` to prepare the DataModel.
   - Starts play mode:
     - `#clientChecks <= 1` → `StudioTestService:ExecutePlayModeAsync()` (Play Solo, 1 server + 1 client).
     - `#clientChecks > 1` → `StudioTestService:ExecuteMultiplayerTestAsync(N)` (1 server + N simulated clients, up to 8).
   - Yields until `EndTest()` is called by the server script.
   - Calls `cleanup()` to remove all tagged instances.
   - Decodes and returns the JSON results array.

4. **`cleanup()`** — destroys all instances tagged with `_EvalRunnerPlayMode` across `ServerScriptService`, `StarterPlayerScripts`, and `ReplicatedStorage`. Restores `StarterPlayer.LoadCharacterAppearance = true`.

### `UIBuilder.lua` — The Panel

Builds the `DockWidgetPluginGui` using native Roblox UI instances (no Roact/React dependency):

- **Top bar** — title + Reset / Refresh / Export buttons.
- **Status bar** — shows current state ("Ready", "Running: eval_name", "Starting play-mode checks...").
- **Eval list** (top half) — a `ScrollingFrame` with one row per eval. Each row has the eval name, metadata warnings (e.g., "no ref"), a pass/fail counter, and a Run button. Rows are clickable to select.
- **Result detail** (bottom half) — shows the selected eval's per-check results with `+` (pass, green) or `-` (fail, red) and its message. Play-mode results appear with `[server]` / `[client:N]` prefixes. Errors show in red.

Exposes: `ui.refresh()`, `ui.showResult()`, `ui.updateRow()`, `ui.clearResult()`, `ui.setRunning()`, `ui.setStatus()`.