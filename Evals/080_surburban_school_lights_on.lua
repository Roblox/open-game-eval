--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "080_surburban_school_lights_on",
	prompt = {
		{
			{
				role = "user",
				content = [[Make every light in the school start in the 'on' state.]],
				request_id = "s20250825_010",
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
	for _, lights in game:GetService("Workspace").School.Lights:GetChildren() do
		if lights:FindFirstChild("LightsOn") then
			lights["LightsOn"].Value = true
		end
		for _, light in lights:GetChildren() do
			if light:IsA("Model") then
				if light.Name == "Light" then
					light.Light.Material = Enum.Material.Neon
					light.Light.SpotLight.Enabled = true
				end
			end
		end
	end
end

eval.check_scene = function()
	for _, lights in game:GetService("Workspace").School.Lights:GetChildren() do
		if lights:FindFirstChild("LightsOn") then
			assert(lights["LightsOn"].Value == true, "LightsOn value not true")
		end
		for _, light in lights:GetChildren() do
			if light:IsA("Model") then
				if light.Name == "Light" then
					assert(light.Light.Material == Enum.Material.Neon, "Light material not set to Neon")
					assert(light.Light.SpotLight.Enabled == true, "Light did not turn on")
				elseif light.Name == "LightSwitch" then
					assert(
						light.Interactive.Orientation.X > 0 or light.Interactive.Orientation.Z > 0,
						"Light switch is not flipped not turn on"
					)
				end
			end
		end
	end
end

eval.check_game = function() end

return eval
