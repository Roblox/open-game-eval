--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
    scenario_name = "008_spawn_as_r6",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[make every player spawn as a R6 test dummy as their character for now.]],
                        request_id = "s20250626_004"
                    }
                }
            },
    place = "baseplate.rbxl"

}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

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
	local starterPlayer = game:GetService("StarterPlayer")
	local char = starterPlayer:FindFirstChild("StarterCharacter")
	assert(char, "No StarterCharacter found which is required for solving this query.")
	assert(char.Humanoid.RigType == Enum.HumanoidRigType.R6, "StarterCharacter is not an R6 rig!")
end

eval.check_game = function()
    local players = game:GetService("Players")
	local player = if #players:GetPlayers() > 0 then players:GetPlayers()[1] else players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	assert(humanoid.RigType == Enum.HumanoidRigType.R6, "Character spawned is not an R6 rig.")
end

return eval
