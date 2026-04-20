--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "089_fps_box_fling_harder",
	prompt = {
		{
			{
				role = "user",
				content = [[Make the boxes fling harder when you shoot them.]],
				request_id = "s20250825_019",
			},
		},
	},
	place = "fps_system.rbxl",
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local StarterPack = game:GetService("StarterPack")
local Defaults = {
	Blaster = 5,
	AutoBlaster = 2,
}

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

	local AutoBlaster = StarterPack:FindFirstChild("AutoBlaster")
	local Blaster = StarterPack:FindFirstChild("Blaster")

	AutoBlaster:SetAttribute("unanchoredImpulseForce", Defaults.AutoBlaster)
	Blaster:SetAttribute("unanchoredImpulseForce", Defaults.Blaster)
end

eval.reference = function()
	local AutoBlaster = StarterPack.AutoBlaster
	local Blaster = StarterPack:FindFirstChild("Blaster")
	AutoBlaster:SetAttribute("unanchoredImpulseForce", Defaults.AutoBlaster * 2)
	Blaster:SetAttribute("unanchoredImpulseForce", Defaults.Blaster * 2)
end

eval.check_scene = function()
	local AutoBlaster = StarterPack.AutoBlaster
	local Blaster = StarterPack:FindFirstChild("Blaster")
	local autoBlasterForce = AutoBlaster:GetAttribute("unanchoredImpulseForce")
	local blasterForce = Blaster:GetAttribute("unanchoredImpulseForce")

	local validIncreases = autoBlasterForce >= Defaults.AutoBlaster * 1.5 and blasterForce >= Defaults.Blaster * 1.5
	assert(validIncreases, "One or more blasters did not have valid force increases!")
end

eval.check_game = function() end

return eval
