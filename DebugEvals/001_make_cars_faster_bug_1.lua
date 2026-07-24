--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "001_make_cars_faster_bug_1",
	prompt = { "I'm trying to run a script to make the cars faster, but it keeps erroring out saying it can't find the car's 'Engine'. Please fix without revising the script." },
	place = "racing.rbxl"
}

eval.setup = function()
	local car = game:GetService("ReplicatedStorage"):FindFirstChild("Car")
	if not car then return end

	local engine = car:FindFirstChild("Engine")
	if not engine then return end

	engine.Name = "Motor"
end

eval.reference = function()
	local car = game:GetService("ReplicatedStorage"):FindFirstChild("Car")
	if not car then return end

	local target = car:FindFirstChild("Motor")
	if not target then return end

	target.Name = "Engine"
end

eval.check_scene = function()
	local car = game:GetService("ReplicatedStorage"):FindFirstChild("Car")
	assert(car, "Car is missing from ReplicatedStorage")
	assert(car:FindFirstChild("Engine"), "Car.Engine was not restored")
	assert(not car:FindFirstChild("Motor"), "Car.Motor still exists")
end

eval.check_game = function() end

return eval
