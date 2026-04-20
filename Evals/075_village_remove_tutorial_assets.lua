--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "075_village_remove_tutorial_assets",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Remove tutorial assets from the map]],
                        request_id = "s20250825_005"
                    }
                }
            },
    place = "village.rbxl",
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
end

eval.reference = function()
end

eval.check_scene = function()
	local infoAssets = game:GetService("Workspace"):FindFirstChild("Info NPCs")
	local infoAssetsRemoved = false
	if not infoAssets then
		infoAssetsRemoved = true
	end
	if infoAssets then
		print(#infoAssets:GetChildren() == 0)
		if #infoAssets:GetChildren() == 0 then
			infoAssetsRemoved = true
		end
	end
	assert(infoAssetsRemoved, "Not all tutorial assets removed")
	
end

eval.check_game = function()
end

return eval
