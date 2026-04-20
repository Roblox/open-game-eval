--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
    scenario_name = "023_music_playing_part",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[write me a script to play and stop music when within certain trigger parts.]],
                        request_id = "s20250722_009"
                    }
                }
            },
    place = "baseplate.rbxl",

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)



eval.setup = function()

    --Insert music
    local musicSound = Instance.new('Sound')
    musicSound.Name = 'music'
    musicSound.SoundId = 'rbxassetid://1848354536'
    musicSound.Looped = true
    musicSound.Volume = 0
	musicSound.Parent = game:GetService('Workspace')

    -- Create the Trigger Part
    local triggerPart = Instance.new('Part')
    triggerPart.Name = 'trigger'
    triggerPart.Size = Vector3.new(20, 10, 20)
    triggerPart.Position = Vector3.new(20, 5, 20)
    triggerPart.CanCollide = false
    triggerPart.Anchored = true
    triggerPart.Parent = workspace

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
	task.wait(.5)
	assert(music.IsPlaying, "Music is not playing, when moved player into part")

	character:PivotTo(CFrame.new(100, 5, 100))
	task.wait(.5)
	assert(not music.IsPlaying, "Music is still playing, even though we walked away from the part.")

	task.wait(5)
end

return eval
