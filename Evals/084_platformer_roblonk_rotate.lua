--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "084_platformer_roblonk_rotate",
	prompt = {
		{
			{
				role = "user",
				content = [[Can you rotate roblonk by 90 degrees?]],
				request_id = "s20250825_014",
			},
		},
	},
	place = "platformer.rbxl",
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local workspace = game:GetService("Workspace")
local startPosition = nil

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

	local roblonk = workspace.LevelArt.SkyMeshes.RoBlonk
	startPosition = roblonk:GetPivot()
end

eval.reference = function()
	local roblonk = workspace.LevelArt.SkyMeshes.RoBlonk
	roblonk:PivotTo(roblonk:GetPivot() * CFrame.Angles(0, math.rad(90), 0))
end

eval.check_scene = function()
	local workspace = game:GetService("Workspace")
	local roblonk = workspace.LevelArt.SkyMeshes.RoBlonk
	local newPivot = roblonk:GetPivot()
	local transformation = startPosition:ToObjectSpace(newPivot)
	local _, rotY, _ = transformation:ToEulerAnglesYXZ()
	local degreesY = math.deg(rotY)

	print(degreesY)
	print(math.abs(degreesY - 90.0))

	local epsilon = 0.0001
	local isRotationCorrect = math.abs(degreesY - 90.0) < epsilon
	assert(roblonk:GetPivot() ~= startPosition, "Roblonk was not rotated")
	assert(isRotationCorrect, "Not rotated 90")
end

eval.check_game = function() end

return eval
