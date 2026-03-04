--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "001_make_cars_faster_bug_2",
	prompt = { "I was trying to make the cars faster, but now they don't spawn in the game at all and I'm getting errors. I think I might have moved the car prefab somewhere by accident." },
	place = "racing.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local attributesToScrape = { "_speed", "acceleration", "forwardMaxSpeed", "maxSpeedTorque", "reverseMaxSpeed" }
local originalSpeedInfo = {}

eval.setup = function()
local selectionService = game:GetService("Selection")
local HttpService = game:GetService("HttpService")
local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
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

local car = game:GetService("ReplicatedStorage"):FindFirstChild("Car")
assert(car, "Car not found in ReplicatedStorage for setup")
local target = car:FindFirstChild("Engine")
assert(target, "Engine not found in Car for setup")

-- This part is from the original setup, to populate the up-scoped `originalSpeedInfo` table
-- which is used by the check function. `attributesToScrape` is also an up-scoped local.
local attributesToScrape = { "_speed", "acceleration", "forwardMaxSpeed", "maxSpeedTorque", "reverseMaxSpeed" }
for _, attr in ipairs(attributesToScrape) do
	originalSpeedInfo[attr] = tonumber(target:GetAttribute(attr))
end

-- This is the bug: the car prefab was moved to the wrong service
car.Parent = game:GetService("ServerStorage")
end

eval.reference = function()
-- Find the car in the wrong location first
local car = game:GetService("ServerStorage"):FindFirstChild("Car")

-- If not found there, check the correct location as a fallback
if not car then
	car = game:GetService("ReplicatedStorage"):FindFirstChild("Car")
end

assert(car, "Could not find Car model in either ServerStorage or ReplicatedStorage")

-- Fix the environment by moving it back to the correct location
car.Parent = game:GetService("ReplicatedStorage")

-- Now apply the original reference logic
local target = car:FindFirstChild("Engine")
assert(target, "Could not find Engine in Car model")

target:SetAttribute("_speed", target:GetAttribute("_speed") * 2)
target:SetAttribute("acceleration", target:GetAttribute("acceleration") * 2)
target:SetAttribute("forwardMaxSpeed", target:GetAttribute("forwardMaxSpeed") * 2)
target:SetAttribute("maxSpeedTorque", target:GetAttribute("maxSpeedTorque") * 2)
target:SetAttribute("reverseMaxSpeed", target:GetAttribute("reverseMaxSpeed") * 2)
end

eval.check_scene = function()
	local target = game:GetService("ReplicatedStorage"):FindFirstChild("Car"):FindFirstChild("Engine")

	local failed = {}
	for _, attr in ipairs(attributesToScrape) do
		if target:GetAttribute(attr) ~= originalSpeedInfo[attr] * 2 then
			table.insert(failed, { attr, target:GetAttribute(attr), originalSpeedInfo[attr] * 2 })
		end
	end

	local failedString = "Eval failed, not enough attributes were doubled."

	for _, attrData in ipairs(failed) do
		failedString ..= string.format(
			"\nAttribute %s is %s, when we expected %s",
			attrData[1],
			attrData[2],
			attrData[3]
		)
	end

	assert(#failed <= 3, failedString)
end

eval.check_game = function() end

return eval
