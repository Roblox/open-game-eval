--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)
local utils_runs = require(LoadedCode.EvalUtils.utils_runs)


local eval: BaseEval = {
    scenario_name = "010_left_shift_sprint_5s",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Can you make a script where if you hold the left shift button your walkspeed gets 20 added to it and if you hold it for 5 seconds your walkspeed goes back to normal?]],
                        request_id = "s20250626_008"
                    }
                }
            },
    place = "baseplate.rbxl",
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
	_G.originalObjects = utils_he.getAllReasonableItems()
end

eval.reference = function()
end

eval.check_scene = function()
end

eval.runConfig.serverCheck = function()
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local VirtualInputManager = game:GetService("VirtualInputManager")
	local leftShiftKey = Enum.KeyCode.LeftShift

	local players = game:GetService("Players")
	local localPlayer = players.LocalPlayer
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid")
	local lastSpeed = hum.WalkSpeed
	local success = false

	utils_runs.sendKeyEvent(true, leftShiftKey)
	task.wait(0.5)
	print(hum.WalkSpeed)
	assert(hum.WalkSpeed == lastSpeed+20, "Walkspeed did not increase by 20")

	task.wait(6) -- Changing the query to 5s along with this wait. (Previously 100 seconds)
	utils_runs.sendKeyEvent(false, leftShiftKey)

	assert(hum.WalkSpeed == lastSpeed, "After 5 seconds, Walkspeed did not return to normal")
end)

return eval
