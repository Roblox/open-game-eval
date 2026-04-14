--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
	scenario_name = "057_surburban_no_trespassing",
	prompt = {
		{
			{
				role = "user",
				content = [[No trespassing: when player enters the fenced yard, they will receive 10 damage.]],
				request_id = "s20250804_025"
			}
		}
	},
	place = "surburban.rbxl",
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
	local fence = game:GetService("Workspace").Yard.Fence;
	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()

	player.Character:PivotTo(CFrame.new(-35.4, 6.5, 121.3)*CFrame.new(0,0,-5));
	task.wait(0.5);
	player.Character.Humanoid:MoveTo((CFrame.new(-35.4, 6.5, 121.3)*CFrame.new(0,0,5)).Position);
	task.wait(1);
	local currentHealth = player.Character.Humanoid.Health;
	assert(player.Character.Humanoid.Health < player.Character.Humanoid.MaxHealth, "Player did not take damage from walking into the back yard");
	task.wait(0.5);
	player.Character.Humanoid:MoveTo((CFrame.new(-35.4, 6.5, 121.3)*CFrame.new(0,0,-5)).Position);
	task.wait(1);
	assert(player.Character.Humanoid.Health >= currentHealth, "Player took damage from exiting the back yard");

end

return eval
