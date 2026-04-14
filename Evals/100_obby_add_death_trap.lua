--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "100_obby_add_death_trap",
	prompt = {
		{
			{
				role = "user",
				content = [[Add a spinning death trap]],
				request_id = "s20250825_030",
			},
		},
	},
	place = "classic_obby.rbxl",
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local oldWorkspace = game:GetService("Workspace"):GetDescendants()
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
	local spinner = Instance.new("Part")
	spinner.Size = Vector3.new(25, 1, 2)
	spinner.BrickColor = BrickColor.Red()
	spinner.Anchored = true

	local spinScript = Instance.new("Script")
	spinScript.Source = [[
		local function touched(part)
			local humanoid = part.Parent:FindFirstChild("Humanoid")
			if humanoid then
				humanoid.Health = 0
			end
		end
		script.Parent.Touched:Connect(touched)
	
		while task.wait() do
			script.Parent.CFrame = script.Parent.CFrame * CFrame.Angles(0, .05, 0)
		end
	]]

	spinScript.Parent = spinner
	spinner.Parent = game:GetService("Workspace")
end

eval.check_scene = function()
	local diff = utils_he.table_difference(oldWorkspace, game:GetService("Workspace"):GetDescendants())
	print(#diff)
	assert(#diff > 0, "Nothing added")
end

eval.check_game = function()
	local diff = utils_he.table_difference(oldWorkspace, game:GetService("Workspace"):GetDescendants())
	local position
	local pivotTable = {}
	for _, obj in diff do
		if obj:IsA("Model") or obj:IsA("BasePart") then
			position = obj:GetPivot()
			table.insert(pivotTable, { object = obj, pivot = position })
			break
		end
	end
	assert(position, "No Baseparts Added")
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(0.5)
	local hp = character.Humanoid.Health
	character:PivotTo(position)
	task.wait(3)
	local anyChange = false
	for _, objE in pivotTable do
		local obj = objE.object
		local oldPivot = objE.pivot
		local newPivot = objE.object:GetPivot()
		if newPivot ~= oldPivot then
			print(objE)
			anyChange = true
		end
	end
	assert(anyChange, "No Movement on any of the parts")
	assert(character.Humanoid.Health < 100, "Player did not take any damage when on the part")
end

return eval
