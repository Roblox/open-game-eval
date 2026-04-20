--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "113_racing_extend_laps",
	prompt = {
		{
			{
				role = "user",
				content = [[Make the races last longer. I want them to be 20 laps.]],
				request_id = "s20250919_010",
			},
		},
	},
	place = "racing.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	},
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
	local raceModel = game:GetService("Workspace"):FindFirstChild("Race")
	if raceModel then
		raceModel:SetAttribute("numberOfLaps", 20)
	end
end

eval.check_scene = function()
	local raceModel = game:GetService("Workspace"):FindFirstChild("Race")
	if raceModel then
		local numberOfLaps = raceModel:GetAttribute("numberOfLaps")
		assert(numberOfLaps == 20, "Number of laps were not changed to 20")
	end
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function() end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService) end)

return eval
