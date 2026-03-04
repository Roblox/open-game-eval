--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "001_make_cars_faster_bug_1",
	prompt = { "I'm trying to run a script to make the cars faster, but it keeps erroring out saying it can't find the car's 'Engine'. I looked in the model and it seems someone renamed it to 'Motor'. The script needs to be updated to find the right part." },
	place = "racing.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local attributesToScrape = { "_speed", "acceleration", "forwardMaxSpeed", "maxSpeedTorque", "reverseMaxSpeed" }
local originalSpeedInfo = {}

eval.setup = function()
local car = game:GetService("ReplicatedStorage"):FindFirstChild("Car")
if not car then return end

local engine = car:FindFirstChild("Engine")
if not engine then return end

-- Run original setup logic to populate the originalSpeedInfo upvalue
-- so the check_scene function has the baseline values.
local attributesToScrape = { "_speed", "acceleration", "forwardMaxSpeed", "maxSpeedTorque", "reverseMaxSpeed" }
for _, attr in ipairs(attributesToScrape) do
	originalSpeedInfo[attr] = tonumber(engine:GetAttribute(attr))
end

-- Introduce the bug by renaming the part AFTER capturing its original state.
engine.Name = "Motor"
end

eval.reference = function()
local car = game:GetService("ReplicatedStorage"):FindFirstChild("Car")
if not car then return end

-- Find the part by its new, incorrect name 'Motor'
local target = car:FindFirstChild("Motor")
if not target then return end

target:SetAttribute("_speed", target:GetAttribute("_speed") * 2)
target:SetAttribute("acceleration", target:GetAttribute("acceleration") * 2)
target:SetAttribute("forwardMaxSpeed", target:GetAttribute("forwardMaxSpeed") * 2)
target:SetAttribute("maxSpeedTorque", target:GetAttribute("maxSpeedTorque") * 2)
target:SetAttribute("reverseMaxSpeed", target:GetAttribute("reverseMaxSpeed") * 2)

-- Rename the part back to 'Engine' so the unit test can find it
target.Name = "Engine"
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
