--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "004_reduce_car_friction_enable_sliding_bug_2",
	prompt = { "I tried to make the cars more slippery so they could drift, but now they feel even more stuck to the road and difficult to turn. It feels like the friction went up instead of down. What's wrong?" },
	place = "racing.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local GlobalTable = {
	wheels = nil,
	originalKinFriction = nil,
	originalStaticFriction = nil,
}

eval.setup = function()
-- This part is essential from the original setup
GlobalTable.wheels = game:GetService("ReplicatedStorage"):FindFirstChild("Car"):FindFirstChild("Wheels")
GlobalTable.originalKinFriction = GlobalTable.wheels:GetAttribute("kineticFriction")
GlobalTable.originalStaticFriction = GlobalTable.wheels:GetAttribute("staticFriction")

-- Buggy logic: Increase friction instead of decreasing it
-- This is a plausible mistake where a developer might multiply instead of divide
GlobalTable.wheels:SetAttribute("kineticFriction", GlobalTable.originalKinFriction * 2)
GlobalTable.wheels:SetAttribute("staticFriction", GlobalTable.originalStaticFriction * 2)
end

eval.reference = function()
-- Reduce friction by half
local wheels = game:GetService("ReplicatedStorage"):FindFirstChild("Car"):FindFirstChild("Wheels")
wheels:SetAttribute("kineticFriction", GlobalTable.originalKinFriction * 0.5)
wheels:SetAttribute("staticFriction", GlobalTable.originalStaticFriction * 0.5)
end

eval.check_scene = function()
	assert(
		GlobalTable.wheels:GetAttribute("kineticFriction") < GlobalTable.originalKinFriction
			or GlobalTable.wheels:GetAttribute("staticFriction") < GlobalTable.originalStaticFriction,
		"Friction not reduced on the cars."
	)
end

eval.check_game = function() end

return eval
