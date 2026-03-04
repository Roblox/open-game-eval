--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "023_music_playing_part_bug_2",
	prompt = { "I created a trigger part that's supposed to play music when a player walks into it, but the music never starts. The part and the sound are both in the Workspace, but nothing happens." },
	place = "baseplate.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
--Insert music
local musicSound = Instance.new("Sound")
musicSound.Name = "music"
musicSound.SoundId = "rbxassetid://1848354536"
musicSound.Looped = true
musicSound.Volume = 0
musicSound.Parent = game:GetService("Workspace")

-- Create the Trigger Part
local triggerPart = Instance.new("Part")
triggerPart.Name = "trigger"
triggerPart.Size = Vector3.new(20, 10, 20)
triggerPart.Position = Vector3.new(20, 5, 20)
triggerPart.CanCollide = false
triggerPart.Anchored = true
triggerPart.Parent = workspace

-- THE BUG: Disable touch events on the trigger part, preventing the Touched event from firing.
triggerPart.CanTouch = false
end

eval.reference = function()
-- Fix the environment by re-enabling touch events on the trigger part.
local trigger = game:GetService("Workspace"):FindFirstChild("trigger")
if trigger and trigger:IsA("BasePart") then
	trigger.CanTouch = true
end

-- Original reference code to create the music script.
local script = Instance.new("Script")
script.Source = [[

	local playing = false
	local trigger = game:GetService("Workspace").trigger
	trigger.Touched:Connect(function(touched)
		if touched.Parent:FindFirstChild("Humanoid") then
			print("enter", game:GetService("Workspace").music.IsPlaying)
			if playing == false then
				playing = true
				game:GetService("Workspace").music:Play()
			end
		end
	end)

	trigger.TouchEnded:Connect(function(touched)
		if touched.Parent:FindFirstChild("Humanoid") then
			print("exit", game:GetService("Workspace").music.IsPlaying)

			if playing == true then
				playing = false
				game:GetService("Workspace").music:Stop()
			end
		end
	end)

	]]
script.Parent = game:GetService("Workspace")
end

eval.check_scene = function() end

eval.check_game = function()
	--[[
		There may be an issue when this evaluation is ran in the test environment.
		A 'perfect' implementation of this query would require the music to only be ran
		on the game client, not server.

		So the immediate solution then feels like a RemoteFunction would be necessary.
		However this creates a catch-22, since our end we execute code via a plugin
		already running in Client context.
	]]

	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local trigger = game:GetService("Workspace").trigger
	local music = game:GetService("Workspace").music

	task.wait(1)
	character:PivotTo(trigger:GetPivot())
	task.wait(0.5)
	assert(music.IsPlaying, "Music is not playing, when moved player into part")

	character:PivotTo(CFrame.new(100, 5, 100))
	task.wait(0.5)
	assert(not music.IsPlaying, "Music is still playing, even though we walked away from the part.")

	task.wait(5)
end

return eval
