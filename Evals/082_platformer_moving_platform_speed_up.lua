--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "082_platformer_moving_platform_speed_up",
	prompt = {
		{
			{
				role = "user",
				content = [[Make the moving platforms speed up by 5.]],
				request_id = "s20250825_012",
			},
		},
	},
	place = "platformer.rbxl",
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
	for _, platform in game:GetService("Workspace"):GetDescendants() do
		if platform:IsA("Model") and platform.Name == "MovingPlatform" then
			local speed = platform:GetAttribute("speed")
			platform:SetAttribute("speed", speed + 5)
		end
	end
	local platformTemplate = game:GetService("ServerStorage")["Template Library"]["Gameplay Objects"].MovingPlatform
	local speed = platformTemplate:GetAttribute("speed")
	platformTemplate:SetAttribute("speed", speed + 5)
end

eval.check_scene = function()
	for _, platform in game:GetService("Workspace"):GetDescendants() do
		if platform:IsA("Model") and platform.Name == "MovingPlatform" then
			assert(platform:GetAttribute("speed") == 15, "MovingPlatform speed did not increase by 5")
		end
	end
	local platformTemplate = game:GetService("ServerStorage")["Template Library"]["Gameplay Objects"].MovingPlatform
	assert(platformTemplate:GetAttribute("speed") == 15, "MovingPlatform speed did not increase by 5")
end

eval.check_game = function() end

return eval
