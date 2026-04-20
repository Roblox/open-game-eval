--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
	scenario_name = "075_create_npc_enemy",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Create an NPC enemy]],
                        request_id = "s20250709_005r1"
                    }
                }
            },
    place = "laser_tag.rbxl",

local selection_context_json = "[]"
local table_selection_context = HttpService:JSONDecode(selection_context_json)
local OldState = game:GetService("Workspace"):GetDescendants()

eval.setup = function()
    local selection_service = game:GetService("Selection")
    local selected_instances = {}
    for _, selection in ipairs(table_selection_context) do
        for _, instance in ipairs(game:GetDescendants()) do
            if instance.Name == selection.instanceName and instance:IsA(selection.className) then
                selected_instances[#selected_instances + 1] = instance
                break
            end
        end
    end
    selection_service:Set(selected_instances)
end

eval.reference = function()
end

eval.check_scene = function()
	local newObjects = utils_he.table_difference(OldState, game:GetService("Workspace"):GetDescendants())

	assert(#newObjects > 0, "Nothing new was added to Workspace.")

	local hasHumanoid, hasScript, hasPart, usesMoveTo = false, false, false, false

	for _, obj in pairs(newObjects) do
		if obj:IsA("BasePart") then
			hasPart = true
		elseif obj:IsA("LuaSourceContainer") then
			hasScript = true
			if obj.Source:find("MoveTo") then
				usesMoveTo = true
			end
		elseif obj:IsA("Humanoid") then
			hasHumanoid = true
		end
	end

	assert(hasHumanoid, "Humanoid is expected for this NPC to run. A solution without a humanoid would be very challenging to make.")
	assert(hasScript, "No new scripts were added.")
	assert(hasPart, "No new parts were added.")
	assert(usesMoveTo, "Use of Humanoid:MoveTo() would required to move an NPC using a Humanoid.")

	print("Success.")
end

eval.check_game = function()
end

return eval
