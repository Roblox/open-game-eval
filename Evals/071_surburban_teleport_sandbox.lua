--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
    scenario_name = "071_surburban_teleport_sandbox",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[When player step on the sandbox, they will be teleported to the spawn location.]],
                        request_id = "s20250825_001"
                    }
                }
            },
    place = "surburban.rbxl",
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

eval.setup = function()

    local selectionService = game:GetService("Selection")
    local selectedInstances = {}
    for _, selection in ipairs(TableSelectionContext) do
        for _, instance in ipairs(game:GetDescendants()) do
            if instance.Name == selection.instanceName and instance:IsA(selection.className) then
                selectedInstances[#selectedInstances + 1] = instance
                break
            end
        end
    end
    selectionService:Set(selectedInstances)
end

eval.reference = function()
end

eval.check_scene = function()
end

assert(eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function()

	local players = game:GetService("Players")
    local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
    local character = player.Character or player.CharacterAdded:Wait()

	local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:WaitForChild("SpawnLocation")
	local yard = Workspace:FindFirstChild("Yard") or Workspace:WaitForChild("Yard")
	local sandbox = yard:FindFirstChild("Sandbox") or yard:WaitForChild("Sandbox")

	character:PivotTo(sandbox:GetPivot() + Vector3.yAxis * 5)
    print("sandbox", character:GetPivot().Position)
    print("spawnLocation", spawnLocation:GetPivot().Position)
	task.wait(1)
    print("character position", character:GetPivot().Position)
	local posDiff = character:GetPivot().Position - spawnLocation:GetPivot().Position
	local distance = Vector3.new(posDiff.X, 0, posDiff.Z).Magnitude
	assert(distance < 5, `Character is too far from spawn location! Distance: {distance}`)

end)

return eval
