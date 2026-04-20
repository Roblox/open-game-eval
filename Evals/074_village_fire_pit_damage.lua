--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "074_village_fire_pit_damage",
	prompt = {
		{
			{
				role = "user",
				content = [[Make all fire pits in the game damage the player when walked over]],
				request_id = "s20250825_004",
			},
		},
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
	for _, obj in workspace:GetDescendants() do
		if obj.Name == "FirePart" then
			local FirePart = obj
			local newScript = Instance.new("Script")
			-- newScript.RunContext = Enum.RunContext.Client
			newScript.Source = [[
			local part = script.Parent
			part.Touched:Connect(function(part)
				if part.Parent:FindFirstChild("Humanoid") then
					local humanoid = part.Parent:FindFirstChild("Humanoid")
					humanoid.Health -= .1
				end
			end)
			]]
			newScript.Parent = FirePart
			newScript.Enabled = false
			task.wait()
			newScript.Enabled = true
		end
	end
end

eval.check_scene = function() end

eval.check_game = function()
	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local health = character:WaitForChild("Humanoid", math.huge).Health
	local rootPart = character:WaitForChild("HumanoidRootPart", math.huge)
	local firePartCount = 0

	for _, object in ipairs(workspace:GetDescendants()) do
		if object.Name == "FirePart" then
			local FirePart = object
			local OriginalSpace = utils_he.getAllReasonableItems()
			local touchSuccess = false
			local humanoid = character:WaitForChild("Humanoid", math.huge)
			local health = humanoid.Health
			humanoid.Health = 100
			health = health

			local lostHealth = false

			for i = 1, 8, 1 do
				lostHealth = false
				task.wait(0.1)
				rootPart.CFrame = FirePart.CFrame
				if
					character:WaitForChild("Humanoid", math.huge).Health < health
					and (character.HumanoidRootPart.Position - FirePart.CFrame.p).Magnitude < 1
				then
					lostHealth = true
				end
				if lostHealth then
					break
				end
				task.wait()
			end

			assert(lostHealth, "Player did not take any damage.")
		end
	end
end

return eval
