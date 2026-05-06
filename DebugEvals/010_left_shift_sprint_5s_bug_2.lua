--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)
local utils_runs = require(LoadedCode.EvalUtils.utils_runs)

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "010_left_shift_sprint_5s_bug_2",
	prompt = { "When I hold Left Shift to sprint, it works, but if I let go of the key early, I keep sprinting for the full 5 seconds. I should stop sprinting as soon as I release the key." },
	place = "baseplate.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
local newScript = Instance.new("LocalScript")
newScript.Name = "SprintScript"
newScript.Source = [[
local players = game:GetService("Players")
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local UserInputService = game:GetService("UserInputService")
local running = false
local currentSpeed = character:WaitForChild("Humanoid").WalkSpeed

function getTool()
	for _, kid in ipairs(script.Parent:GetChildren()) do
		if kid.className == "Tool" then return kid end
	end
	return nil
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- Ignore input if the player is chatting or in a menu

	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.LeftShift then
			players.LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed + 20
			wait(5)
			players.LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
		end
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
		return
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed, third)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			local currentSpeed = players.LocalPlayer.Character.Humanoid.WalkSpeed
			players.LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
		end
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
		if input.KeyCode == Enum.KeyCode.ButtonL3 then
			--setRunSpeed(false)
		end
	end
end)
]]
newScript.Enabled = true
newScript.Parent = game:GetService("StarterPlayer").StarterPlayerScripts
print("buggy sprint script added")
end

eval.reference = function()
local newScript = Instance.new("LocalScript")
newScript.Name = "SprintScript"
newScript.Source = [[
local players = game:GetService("Players")
local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local UserInputService = game:GetService("UserInputService")
local running = false
local currentSpeed = character:WaitForChild("Humanoid").WalkSpeed

function getTool()
	for _, kid in ipairs(script.Parent:GetChildren()) do
		if kid.className == "Tool" then return kid end
	end
	return nil
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end -- Ignore input if the player is chatting or in a menu

	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.LeftShift then
			players.LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed + 20
			wait(5)
			players.LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
		end
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
		return
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed, third)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			players.LocalPlayer.Character.Humanoid.WalkSpeed = currentSpeed
		end
	elseif input.UserInputType == Enum.UserInputType.Gamepad1 then
		if input.KeyCode == Enum.KeyCode.ButtonL3 then
			--setRunSpeed(false)
		end
	end
end)
]]
newScript.Enabled = true
newScript.Parent = game:GetService("StarterPlayer").StarterPlayerScripts
print("new sprint script added")
end

eval.check_scene = function() end

eval.runConfig = { clientChecks = {} }

eval.runConfig.serverCheck = function() end

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
	assert(hum.WalkSpeed == lastSpeed + 20, "Walkspeed did not increase by 20")

	task.wait(6) -- Changing the query to 5s along with this wait. (Previously 100 seconds)
	utils_runs.sendKeyEvent(false, leftShiftKey)

	assert(hum.WalkSpeed == lastSpeed, "After 5 seconds, Walkspeed did not return to normal")
end)

return eval
