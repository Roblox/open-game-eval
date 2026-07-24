--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "098_pirate_lose_health_underwater",
	prompt = {
		{
			{
				role = "user",
				content = [[Make the player slowly lose health underwater]],
				request_id = "s20250825_028",
			},
		},
	},
	place = "pirate_island.rbxl",
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
	local newScript = Instance.new("Script")
	newScript.Parent = workspace
	-- newScript.RunContext = Enum.RunContext.Client
	newScript.Source = [[
	local Players = game:GetService("Players")
	local player = Players:FindFirstChildOfClass("Player")
	if not player then
		player = Players.PlayerAdded:Wait()
	end
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")

	while true do
		if char:GetPivot().Position.Y <= 12 and hum:GetStateEnabled(Enum.HumanoidStateType.Swimming) then
			local function takeDamage()
				hum.Health -= 1
			end
			takeDamage()
		end
		task.wait()
	end
	]]
	newScript.Enabled = false
	task.wait()
	newScript.Enabled = true
end

eval.check_scene = function() end

eval.check_game = function(_, _, evalStorage)
	local Players = game:GetService("Players")
	local player = Players:FindFirstChildOfClass("Player")
	if not player then
		player = Players.PlayerAdded:Wait()
	end
	if not evalStorage or not evalStorage.get("isStudio") then
		player:LoadCharacter()
	end
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local tpCFrame = CFrame.new(100, 2, 0)
	char.HumanoidRootPart.CFrame = tpCFrame
	task.wait(1)

	hum.Health = hum.MaxHealth
	local lastHealth = hum.Health
	local healthDrops = 0
	local deadline = os.clock() + 10

	while os.clock() < deadline do
		char.HumanoidRootPart.CFrame = tpCFrame
		task.wait(0.1)

		if hum.Health < lastHealth then
			healthDrops += 1
		end
		lastHealth = hum.Health
	end

	assert(healthDrops >= 3, "health did not decrease repeatedly while underwater")
end

return eval
