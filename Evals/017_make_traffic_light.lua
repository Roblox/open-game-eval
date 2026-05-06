--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "017_make_traffic_light",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[write me a script for a simple 4 way traffic light]],
                        request_id = "s20250722_003"
                    }
                }
            },
    place = "baseplate.rbxl"

}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local OriginalSpace = utils_he.getAllReasonableItems()

eval.setup = function()

    local function removeScripts(parent)
        for _, child in ipairs(parent:GetChildren()) do
            if child:IsA('Script') or child:IsA('ModuleScript') or child:IsA('LocalScript') then
                child:Destroy()
            else
                removeScripts(child)
            end
        end
    end

    local id = 2044205773
    local url = 'rbxassetid://' .. id
    local model = game:GetObjects(url)[1]
    model.Parent = workspace
    model:PivotTo(CFrame.new(Vector3.new(0, 5, 0)))

    removeScripts(model)

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
	local trafficLight = workspace:WaitForChild("TrafficLight")
	local greenLight = trafficLight:WaitForChild("GreenLight")
	local yellowLight = trafficLight:WaitForChild("YellowLight")
	local redLight = trafficLight:WaitForChild("RedLight")

	local greenPointLight = greenLight.Transparency
	local yellowPointLight = yellowLight.Transparency
	local redPointLight = redLight.Transparency
	local scriptsAdded = 0
	local startingLight = nil
	local isRotatingLights = 0

	local on = 0
	local off = 0.8

	local lightStates = {
		[greenLight] = greenPointLight,
		[redLight] = redPointLight,
		[yellowLight] = yellowPointLight
	}


	for light, state in lightStates do
		if state == on then
			startingLight = light
            print("Starting light: " .. startingLight.Name)
		end
	end

	for _, obj in utils_he.table_difference(OriginalSpace, utils_he.getAllReasonableItems()) do
		if obj:IsA("LuaSourceContainer") then
			scriptsAdded += 1
		end
	end

	assert(scriptsAdded >= 1, "A new script was not added to the game.")

	for i = 1, 10, 1 do
		task.wait(0.5) -- shorter time gap to speed up the test
		local greenPointLight2 = greenLight.Transparency
		local yellowPointLight2 = yellowLight.Transparency
		local redPointLight2 = redLight.Transparency
		local newLightStates = {
			[greenLight] = greenPointLight2,
			[redLight] = redPointLight2,
			[yellowLight] = yellowPointLight2
		}

		for light, state in newLightStates do

			if light.Name == startingLight.Name and state >= off then
				for light2, state2 in newLightStates do
					if light2.Name ~= startingLight.Name and state2 == on then
						isRotatingLights += 1
					end
				end
			end
		end

		if isRotatingLights >= 3 then break end

	end

	assert(isRotatingLights >= 3, "light is not rotating")
	print("Success")

end

return eval
