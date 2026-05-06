--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "058_surburban_merrygoround_no_fling",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Can you make the MerryGoRound not fling the player?]],
                        request_id = "s20250804_026"
                    }
                }
            },
    place = "surburban.rbxl"

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
	local merry = game:GetService("Workspace").Playground.MerryGoRound
	local seat = merry:FindFirstChildWhichIsA("Seat")
	
	local players = game:GetService("Players")
    local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
    player:LoadCharacter()
    local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 20)
	
	while seat.Occupant ~= humanoid do
		seat:Sit(humanoid)
		task.wait(0.1)
	end
	
	for i = 1, 10 do -- shortened from 20 to accelerate the test
		assert(seat.Occupant == humanoid, "Player got flung")
		task.wait(1)
	end
	
	print("Success")
end

return eval
