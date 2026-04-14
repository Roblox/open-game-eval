--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "054_surburban_equip_flashlight",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[When player join the game, they should have a flashlight.]],
                        request_id = "s20250804_022"
                    }
                }
            },
    place = "surburban.rbxl",

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
end

eval.reference = function()
end

eval.check_scene = function()
end

eval.check_game = function()
	-- we're gonna check for a general flashlight
	-- in my opinion, the place context ends up not being good enough to rely on
	-- since it just pulls from an asset id
	local players = game:GetService("Players")
    local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
    player:LoadCharacter()
    local character = player.Character or player.CharacterAdded:Wait()
	
	task.wait(0.1)
	
	local flashlight = player.Backpack:FindFirstChildWhichIsA("Tool") -- not gonna allow for hopperbins
	
	assert(flashlight, "No tools exist within the backpack.")
	
	flashlight.Parent = character
	
	-- so, moving it to the character is how you equip items in the engine
	-- and this is just to make sure there isn't an equip event that's important to the flashlight
	
	task.wait(0.1)
	
	local part = flashlight:FindFirstChildWhichIsA("BasePart", true)
	local light = flashlight:FindFirstChildWhichIsA("Light", true) -- Point, Spot, Surface
	
	flashlight:Activate() -- tools can be activated!
	
	task.wait(0.1)
	
	part = part or flashlight:FindFirstChildWhichIsA("BasePart", true)
	light = light or flashlight:FindFirstChildWhichIsA("Light", true)
	
	assert(part, "No part exists within the tool.")
	assert(light, "No light exists within the tool.")
	
	-- Scripts are not necessary to make a flashlight
	
	print("Success")
	
end

return eval
