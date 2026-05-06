--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "022_add_world_time",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Add a script that adds 10 seconds to the world time in Lighting every second.]],
                        request_id = "s20250722_008"
                    }
                }
            },
    place = "baseplate.rbxl"

}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local OriginalSpace = utils_he.getAllReasonableItems()

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
end

eval.check_scene = function()
end

eval.check_game = function()
	local time = game:GetService("Lighting")
	local timeCount = 0
	local lastUpdate = os.clock()
	local lastClockTime = time:GetMinutesAfterMidnight()
	local expected_seconds_change = 10*(1/60)
	local required_checks = 4

	for i = 1, 100 do

		local current = os.clock()
		local timeDelta = current - lastUpdate
		local currentClock = time:GetMinutesAfterMidnight()
		local clockDelta = math.abs(currentClock - lastClockTime)

		assert(timeDelta < 2, "Lighting updates are not happening fast enough.")

		if currentClock ~= lastClockTime then
			-- The first time it changes is very likely to fail since the code will start at an abritrary time
			-- second condition is checking "did it change by 10 seconds" with a couple seconds of wiggle room in case float math gets weird
			if timeDelta >= 1 and clockDelta <= expected_seconds_change*1.05 then
				timeCount += 1
			end
			lastClockTime = time:GetMinutesAfterMidnight()
			lastUpdate = current
		end

		if timeCount >= required_checks then break end
		task.wait(0.1)
	end
	assert(timeCount >= required_checks, "Time is not changing")
end

return eval
