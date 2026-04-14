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
	local player = game.Players.LocalPlayer
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

eval.check_game = function()
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	player:LoadCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local takingDamageScore = 0

	local tpCFrame = CFrame.new(100, 2, 0)

	for i = 1, 128, 1 do
		task.wait()
		char.HumanoidRootPart.CFrame = tpCFrame
		if char:GetPivot().Position.Y <= 12 and hum:GetStateEnabled(Enum.HumanoidStateType.Swimming) then
			local function isTakingDamage()
				if hum.Health < hum.MaxHealth then
					return true
				else
					return false
				end
			end

			local function HealToMax()
				hum.Health = hum.MaxHealth
			end

			if isTakingDamage() then
				takingDamageScore += 1
			end

			HealToMax()
		end
	end
	assert(takingDamageScore >= 100, "not swimming")
end

return eval
