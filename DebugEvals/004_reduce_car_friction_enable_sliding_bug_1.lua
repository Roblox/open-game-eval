--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "004_reduce_car_friction_enable_sliding_bug_1",
	prompt = { "I'm trying to run a script to make the cars drift more, but it's not working. The friction feels exactly the same. I think the script might not be finding the car parts correctly." },
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
-- This code is based on the original eval.setup to ensure GlobalTable is populated correctly.
local wheels = game:GetService("ReplicatedStorage"):FindFirstChild("Car"):FindFirstChild("Wheels")
assert(wheels, "Setup failed: Could not find ReplicatedStorage.Car.Wheels")

-- The original eval file declares GlobalTable in its scope, so we can access it here.
GlobalTable.wheels = wheels
GlobalTable.originalKinFriction = wheels:GetAttribute("kineticFriction")
GlobalTable.originalStaticFriction = wheels:GetAttribute("staticFriction")

-- THE BUG: A part that the script depends on was renamed.
wheels.Name = "Tires"
end

eval.reference = function()
-- Reduce friction by half, accounting for the renamed part
local car = game:GetService("ReplicatedStorage"):FindFirstChild("Car")
assert(car, "Fix failed: Could not find ReplicatedStorage.Car")
local wheels = car:FindFirstChild("Tires") -- Find the part by its new name
assert(wheels, "Fix failed: Could not find the renamed 'Tires' part")

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
