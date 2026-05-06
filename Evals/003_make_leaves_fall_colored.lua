--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
	scenario_name = "003_make_leaves_fall_colored",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make the leaves of trees in this game fall colored]],
                        request_id = "s20250617_003"
                    }
                }
            },
    place = "village.rbxl"

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

	local function partIsAutumnColored(part)
		local h,s,v = part.Color:ToHSV()
		-- I looked at a color wheel for a couple minutes and realized all the autumn colors are next to each other in hue
		-- saturation and value should be over 20 to exclude pure black/pure white

		return (h<=60/360 or h>=340/360) and s>=30/100 and v>=30/100
	end

	for _, tree in ipairs(workspace.Trees:GetChildren()) do
		for _, leaf in ipairs(tree:GetChildren()) do -- It seems this place is set up so all leaves are just within tree and named "Leaves"
			if leaf.Name:lower() == "leaves" and leaf:IsA("BasePart") then
				assert(partIsAutumnColored(leaf), `This leaf isn't autumn colored: {leaf}`)
			end
		end
	end
end

eval.check_game = function()
end

return eval
