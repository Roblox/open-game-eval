--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
    scenario_name = "007_change_logo_cube_green",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Change the Roblox logo like cube to be green]],
                        request_id = "s20250626_001"
                    }
                }
            },
    place = "platformer.rbxl"

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
    local workspace = game:GetService("Workspace")
	local target = workspace:WaitForChild("LevelArt"):WaitForChild("SkyMeshes"):WaitForChild("RoBlonk"):WaitForChild("Roblonx")
	local h,s,v = target.Color:ToHSV()
    assert(h>(70/360) and h<(170/360), "Roblox Part is not properly green.")
end

eval.check_game = function()
end

return eval
