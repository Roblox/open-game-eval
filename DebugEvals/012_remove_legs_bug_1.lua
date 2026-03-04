--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "012_remove_legs_bug_1",
	prompt = { "When my character spawns, they still have legs. The script is supposed to remove them but it doesn't seem to be working." },
	place = "baseplate.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
local script = Instance.new("Script")
script.Name = "RemoveLegs"
script.Source = [[
	local Players = game:GetService("Players")

    local function removeLegs(character)
        if character then
            for _, v in ipairs(character:GetChildren()) do
                if v:IsA("BasePart") and (v.Name:find("leg") or v.Name:find("foot")) then
                    v:Destroy()
                end
            end
        end
    end

    local function onPlayerAdded(player)
        player.CharacterAdded:Connect(removeLegs)
        if player.Character then
            removeLegs(player.Character)
        end
    end

	Players.PlayerAdded:Connect(onPlayerAdded)
    
    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
]]
script.Parent = game:GetService("ServerScriptService")
script.Enabled = true
end

eval.reference = function()
local script = Instance.new("Script")
script.Name = "RemoveLegs"
script.Source = [[
	local Players = game:GetService("Players")

    local function removeLegs(character)
        if character then
            for _, v in ipairs(character:GetChildren()) do
                if v:IsA("BasePart") and (string.lower(v.Name):find("leg") or string.lower(v.Name):find("foot")) then
                    v:Destroy()
                end
            end
        end
    end

    local function onPlayerAdded(player)
        player.CharacterAdded:Connect(removeLegs)
        if player.Character then
            removeLegs(player.Character)
        end
    end

	Players.PlayerAdded:Connect(onPlayerAdded)
    
    -- Handle existing players
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
]]
script.Parent = game:GetService("ServerScriptService")
script.Enabled = true
end

eval.check_scene = function() end

eval.check_game = function()
	local players = game:GetService("Players")
	local player = players.LocalPlayer
	player:LoadCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	task.wait(1)

	for _, v in ipairs(char:GetDescendants()) do
		if v:IsA("BasePart") then
			assert(string.lower(v.Name):find("leg") == nil, "Leg part was found within the character.")
			assert(string.lower(v.Name):find("foot") == nil, "Foot part was found within the character.")
		end
	end
	print("Success!")
end

return eval
