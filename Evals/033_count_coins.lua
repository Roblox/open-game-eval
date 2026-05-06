--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "033_count_coins",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[count the coins in the game, and create same number of parts]],
                        request_id = "s20250722_020"
                    }
                }
            },
    place = "platformer.rbxl"

}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local originalState = Workspace:GetDescendants()
local originalCoins = nil
local GenerationPosition = Vector3.new(0,5,0)

local function GeneratePart(position:Vector3)
	local part = Instance.new("Part")
	part.Size = Vector3.one
	part.Parent = workspace
	part.Position = position
end

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

    local CoinsFolder = Workspace.Gameplay.CoinPickups
    originalNumCoins = #CoinsFolder:GetChildren()
	
end

eval.reference = function()
end

eval.check_scene = function()
	local diff = utils_he.table_difference(originalState,Workspace:GetDescendants())
	assert(#diff == originalNumCoins, `Number of parts added: {#diff} is not equal to coin count: {originalNumCoins}`)
end

eval.check_game = function()
end

return eval
