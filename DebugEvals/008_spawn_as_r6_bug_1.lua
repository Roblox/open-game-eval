--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "008_spawn_as_r6_bug_1",
	prompt = { "Players are spawning as the newer R15 models, but we need them to be the classic R6 blocky characters for our game." },
	place = "baseplate.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
local starterPlayer = game:GetService("StarterPlayer")
local starterCharacter = starterPlayer:FindFirstChild("StarterCharacter")

-- If the place doesn't have a StarterCharacter, create a basic one to ensure the test can run.
if not starterCharacter then
    starterCharacter = Instance.new("Model")
    starterCharacter.Name = "StarterCharacter"
    starterCharacter.Parent = starterPlayer
end

local humanoid = starterCharacter:FindFirstChildOfClass("Humanoid")
if not humanoid then
    humanoid = Instance.new("Humanoid")
    humanoid.Parent = starterCharacter
end

-- This is the bug: the character is explicitly set to R15.
humanoid.RigType = Enum.HumanoidRigType.R15
end

eval.reference = function()
local starterPlayer = game:GetService("StarterPlayer")
local starterCharacter = starterPlayer:FindFirstChild("StarterCharacter")
local humanoid = starterCharacter:FindFirstChild("Humanoid")

humanoid.RigType = Enum.HumanoidRigType.R6
end

eval.check_scene = function()
	local starterPlayer = game:GetService("StarterPlayer")
	local char = starterPlayer:FindFirstChild("StarterCharacter")
	assert(char, "No StarterCharacter found which is required for solving this query.")
	assert(char.Humanoid.RigType == Enum.HumanoidRigType.R6, "StarterCharacter is not an R6 rig!")
end

eval.check_game = function()
	local players = game:GetService("Players")
	local player = if #players:GetPlayers() > 0 then players:GetPlayers()[1] else players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	assert(humanoid.RigType == Enum.HumanoidRigType.R6, "Character spawned is not an R6 rig.")
end

return eval
