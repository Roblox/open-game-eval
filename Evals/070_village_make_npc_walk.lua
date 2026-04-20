--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "070_village_make_npc_walk",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make NPCs walk around randomly]],
                        request_id = "s20250804_038"
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
end

eval.check_game = function()
	local npcInitialPositionMap = {};
	local getNPCs = game:GetService("Workspace")["Info NPCs"]:GetChildren();
	for _,npc in getNPCs do
		if (npc.Name == "NPC Info Guy" and npc.PrimaryPart) then
			npcInitialPositionMap[npc] = npc.PrimaryPart.Position;
		end
	end
	task.wait(2);
	for _,npc in getNPCs do
		if (npcInitialPositionMap[npc]) then
			assert(npc.PrimaryPart.Position ~= npcInitialPositionMap[npc], "NPC did not walk away");
		end
	end
end

return eval
