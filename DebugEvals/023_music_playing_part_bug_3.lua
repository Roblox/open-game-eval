--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "023_music_playing_part_bug_3",
	prompt = { "I set up a trigger part to play music when a player enters it, but it seems to be working backwards. The music stops when I enter the zone and only starts playing again when I leave. What's wrong with my script?" },
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

-- Create the buggy script
local script = Instance.new("Script")
script.Name = "MusicController"
script.Source = [[

	local playing = false
	local trigger = game:GetService("Workspace").trigger
	trigger.Touched:Connect(function(touched)
		if touched.Parent:FindFirstChild("Humanoid") then
			if playing == false then
				playing = true
				game:GetService("Workspace").music:Stop()
			end
		end
	end)

	trigger.TouchEnded:Connect(function(touched)
		if touched.Parent:FindFirstChild("Humanoid") then
			if playing == true then
				playing = false
				game:GetService("Workspace").music:Play()
			end
		end
	end)

]]
script.Parent = game:GetService("Workspace")

end

eval.reference = function()
local existingScript = game:GetService("Workspace"):FindFirstChild("MusicController")
if existingScript then
	existingScript:Destroy()
end

local script = Instance.new("Script")
script.Name = "MusicController"
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
