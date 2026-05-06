--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
	scenario_name = "004_reduce_car_friction_enable_sliding",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Reduce the friction of the cars that spawn in this game with the ground so I can slide around]],
                        request_id = "s20250617_004"
                    }
                }
            },
    place = "racing.rbxl"

}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local GlobalTable = {
	wheels = nil,
	originalKinFriction = nil,
	originalStaticFriction = nil,
}

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
	
	GlobalTable.wheels = game:GetService("ReplicatedStorage"):FindFirstChild("Car"):FindFirstChild("Wheels")
	GlobalTable.originalKinFriction = GlobalTable.wheels:GetAttribute("kineticFriction")
	GlobalTable.originalStaticFriction = GlobalTable.wheels:GetAttribute("staticFriction")
end

eval.reference = function()
end

eval.check_scene = function()
	assert(GlobalTable.wheels:GetAttribute("kineticFriction") < GlobalTable.originalKinFriction or GlobalTable.wheels:GetAttribute("staticFriction") < GlobalTable.originalStaticFriction, "Friction not reduced on the cars.")
end

eval.check_game = function()
end

return eval
