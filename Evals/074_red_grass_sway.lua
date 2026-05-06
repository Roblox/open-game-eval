--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
	scenario_name = "074_red_grass_sway",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make the grass red and sway from side to side]],
                        request_id = "s20250709_004"
                    }
                }
            },
    place = "flat_terrain.rbxl"

}

local selection_context_json = "[]"
local table_selection_context = HttpService:JSONDecode(selection_context_json)
local Workspace = game:GetService("Workspace")
local Terrain = Workspace.Terrain


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
	print("check scene for scenario s20250709_004")
	print("Grass may not be visible until game.Workspace.Terrain.Decoration is set to true. This is not a scriptable property.")
	
	local h, s, v = Terrain:GetMaterialColor(Enum.Material.Grass):ToHSV()
	h *= 360
	s *= 100
	v *= 100
	
	assert(h <= 30 or h >= 330, "Grass Hue is not red.")
	assert(s > 10, "Saturation isn't high enough to be red.")
	assert(Workspace.GlobalWind.Magnitude > 0.5, "GlobalWind isn't set high enough to be noticable.")

	print("Success.")		
end

eval.check_game = function()
end

return eval
