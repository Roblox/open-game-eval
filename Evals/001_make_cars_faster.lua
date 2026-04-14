--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
    scenario_name = "001_make_cars_faster",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make the cars of this game 2x faster]],
                        request_id = "s20250617_001"
                    }
                }
            },
    place = "racing.rbxl",

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local attributesToScrape = {"_speed", "acceleration", "forwardMaxSpeed", "maxSpeedTorque", "reverseMaxSpeed"}
local originalSpeedInfo = {}

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

	local target = game:GetService("ReplicatedStorage"):FindFirstChild("Car"):FindFirstChild("Engine")
	for _, attr in ipairs(attributesToScrape) do
		originalSpeedInfo[attr] = tonumber(target:GetAttribute(attr))
	end
end

eval.reference = function()
end

eval.check_scene = function()
	local target = game:GetService("ReplicatedStorage"):FindFirstChild("Car"):FindFirstChild("Engine")

	local failed = {}
	for _, attr in ipairs(attributesToScrape) do
		if target:GetAttribute(attr) ~= originalSpeedInfo[attr]*2 then
			table.insert(failed, {attr,target:GetAttribute(attr),originalSpeedInfo[attr]*2})
		end
	end

	local failedString = "Eval failed, not enough attributes were doubled."

	for _, attrData in ipairs(failed) do
		failedString..= string.format("\nAttribute %s is %s, when we expected %s", attrData[1], attrData[2], attrData[3])
	end

	assert(#failed<=3, failedString)
end

eval.check_game = function()
end

return eval
