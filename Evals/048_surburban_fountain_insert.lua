--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "048_surburban_fountain_insert",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Place the water fountain on backyard deck and fit the size there.]],
                        request_id = "s20250804_015"
                    }
                }
            },
    place = "surburban.rbxl",
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
    
    local id = 13654372733
    local url = 'rbxassetid://' .. id
    local asset = game:GetObjects(url)[1]
    asset.Parent = workspace

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
	local fountainFolder = game:GetService("Workspace"):FindFirstChild(" water fountain spawn");
	local deck = game:GetService("Workspace")["Urban House"].BackDeck.Deck;
	assert(fountainFolder ~= nil, "Fountain model not found");
	assert(math.round(fountainFolder.Fountain:GetScale()*10)/10 <= 0.6,"Fountain model is too big"); 
	local getParts = game:GetService("Workspace"):GetPartBoundsInBox(CFrame.new(deck:GetBoundingBox().Position), deck:GetExtentsSize()+Vector3.new(0,10,0));
	local isOnDeck = false;
	for _,part in getParts do
		if (part:IsDescendantOf(fountainFolder)) then
			isOnDeck = true;
			break;
		end
	end
	assert(isOnDeck, "Fountain model not placed on deck");
end

eval.check_game = function()
end

return eval
