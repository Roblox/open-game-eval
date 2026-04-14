--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "088_surburban_garage_door_speed_up",
	prompt = {
		{
			{
				role = "user",
				content = [[Double the speed of the garage doors opening.]],
				request_id = "s20250825_018",
			},
		},
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
	local descendants = workspace:GetDescendants()
	for _, obj in descendants do
		if obj:IsA("Folder") and obj.Name == "PhysicsGarageDoor" then
			for _, desc in obj:GetDescendants() do
				if desc:IsA("BodyGyro") then
					desc.P = 400
				end
			end
		end
	end
end

eval.check_scene = function()
	local descendants = workspace:GetDescendants()
	for _, obj in descendants do
		if obj:IsA("Folder") and obj.Name == "PhysicsGarageDoor" then
			for _, desc in obj:GetDescendants() do
				if desc:IsA("BodyGyro") then
					assert(desc.P == 400, "Garage door speed has not doubled")
				end
			end
		end
	end
end

eval.check_game = function() end

return eval
