--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "068_village_collectable_plants",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[The plants in garden cannot be picked up and equipped, can you make it work?]],
                        request_id = "s20250804_036"
                    }
                }
            },
    place = "village.rbxl",
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
end

eval.check_game = function()
	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 60)
	local plant = game:GetService("Workspace").Garden.Plant;
	local target = plant:FindFirstChildWhichIsA("BasePart")
	assert(target, "A BasePart is needed in a plant.")
	character:PivotTo(CFrame.new(target.Position)*CFrame.new(0,5,0));

	task.wait(0.2)

	local tool = character:FindFirstChildOfClass("Tool")

	for i = 1, 10 do
		if tool then break end
		local r = (math.random(-1000, 1000)/3000) + 1
		humanoid:MoveTo(target.Position+Vector3.new(r,0,r))
