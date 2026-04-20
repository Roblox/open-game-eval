--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "097_ugc_mannequin_match_outfit",
	prompt = {
		{
			{
				role = "user",
				content = [[Create a new mannequin for every player currently in the game and make it match their outfit]],
				request_id = "s20250825_027",
			},
		},
	},
	place = "ugc_homestore.rbxl",
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local SSS = game:GetService("ServerScriptService")

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

	local mannequinCreatorScript = SSS:FindFirstChild("MannequinCreator")
	if mannequinCreatorScript then
		mannequinCreatorScript:Destroy()
	end
end

eval.reference = function()
	local mannequinCreatorScript = Instance.new("Script")
	mannequinCreatorScript.Name = "MannequinCreator"
	mannequinCreatorScript.Source = [[local Players = game:GetService("Players")

local function createMannequin(player: Player)
	local model = Players:CreateHumanoidModelFromUserId(player.UserId)
	model.Name = `{player.Name}Mannequin`
	model.Parent = workspace
end

for _, player in ipairs(Players:GetPlayers()) do
	createMannequin(player)
end

Players.PlayerAdded:Connect(function(player: Player) 
	createMannequin(player)
end)]]
	mannequinCreatorScript.Parent = game.ServerScriptService
end

eval.check_scene = function() end

eval.check_game = function()
	local function CompareHumanoidDescriptions(a: HumanoidDescription, b: HumanoidDescription)
		local equal = true
		if a.Face ~= b.Face then
			equal = false
		end
		if a.Head ~= b.Head then
			equal = false
		end
		if a.Pants ~= b.Pants then
			equal = false
		end
		if a.Shirt ~= b.Shirt then
			equal = false
		end
		if a.Torso ~= b.Torso then
			equal = false
		end
		if a.LeftArm ~= b.LeftArm then
			equal = false
		end
		if a.LeftLeg ~= b.LeftLeg then
			equal = false
		end
		if a.RightArm ~= b.RightArm then
			equal = false
		end
		if a.RightLeg ~= b.RightLeg then
			equal = false
		end
		if a.GraphicTShirt ~= b.GraphicTShirt then
			equal = false
		end
		if a.HatAccessory ~= b.HatAccessory then
			equal = false
		end
		if a.FaceAccessory ~= b.FaceAccessory then
			equal = false
		end
		if a.NeckAccessory ~= b.NeckAccessory then
			equal = false
		end
		if a.BackAccessory ~= b.BackAccessory then
			equal = false
		end
		if a.HairAccessory ~= b.HairAccessory then
			equal = false
		end
		if a.FrontAccessory ~= b.FrontAccessory then
			equal = false
		end
		if a.ShouldersAccessory ~= b.ShouldersAccessory then
			equal = false
		end
		if a.WaistAccessory ~= b.WaistAccessory then
			equal = false
		end
		return equal
	end

	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()

	local humanoid: Humanoid = character:FindFirstChild("Humanoid") or character:WaitForChild("Humanoid")
	local description = humanoid:GetAppliedDescription()

	local hasMatch = false
	for i = 1, 20 do
		for i, v in workspace:GetDescendants() do
			if not v:IsA("Model") or v == character or v:HasTag("Mannequin") then
				continue
			end
			local mannequinHumanoid: Humanoid = v:FindFirstChildOfClass("Humanoid")
			if not mannequinHumanoid then
				continue
			end
			local mannequinDescription = mannequinHumanoid:GetAppliedDescription()
			local match = CompareHumanoidDescriptions(description, mannequinDescription)
			if match then
				hasMatch = true
				break
			end
		end
		if hasMatch then
			break
		end
		task.wait(0.1)
	end
	assert(hasMatch, `No Humanoid descriptions matched added players'`)
end

return eval
