--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "103_city_lights_on_off",
	prompt = {
		{
			{
				role = "user",
				content = [[Turn the lights on/off based on time of day]],
				request_id = "s20250825_033",
			},
		},
	},
	place = "modern_city.rbxl",
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
	local newScript = Instance.new("Script")
	-- newScript.RunContext = Enum.RunContext.Client
	newScript.Source = [[
	local lighting = game:GetService("Lighting")
	while task.wait() do
		lighting.ClockTime += .1
		if lighting.ClockTime == 24 then
			lighting.ClockTime = 0
		end
		if lighting.ClockTime >= 5.91 and lighting.ClockTime <= 17.99 then
			for _, v in pairs(game.Workspace:GetDescendants()) do
				if v:IsA("Light") then
					v.Enabled = false
				end
			end
		else
			for _, v in pairs(game.Workspace:GetDescendants()) do
				if v:IsA("Light") then
					v.Enabled = true
				end
			end
		end
	end
	]]
	newScript.Parent = workspace
	newScript.Enabled = false
	task.wait()
	newScript.Enabled = true
end

eval.check_scene = function() end

eval.check_game = function()
	local lighting = game:GetService("Lighting")
	local timechanging = false
	local clockTheTime = lighting.ClockTime
	local correctNightTime = 0
	local correctDayTime = 0

	local function checkLightingTime()
		local seenNight, seenDay = 0, 0

		while seenDay < 500 and seenNight < 500 do
			task.wait(0.1)
			if lighting.ClockTime >= 5.91 and lighting.ClockTime <= 17.99 then
				seenDay += 1

				local allValidLights = true
				for _, v in pairs(game.Workspace:GetDescendants()) do
					if v:IsA("Light") and v.Enabled ~= false then
						allValidLights = false
						break
					end
				end
				correctDayTime += allValidLights and 1 or 0
			else
				seenNight += 1

				local allValidLights = true
				for _, v in pairs(game.Workspace:GetDescendants()) do
					if v:IsA("Light") and v.Enabled ~= true then
						allValidLights = false
						break
					end
				end
				correctNightTime += allValidLights and 1 or 0
			end
			if correctNightTime >= 50 and correctDayTime >= 50 then
				break
			end
		end
	end

	local function checkTime()
		for i = 1, 50, 1 do
			task.wait(0.1)
			local currentTime = lighting.ClockTime
			if currentTime ~= clockTheTime then
				timechanging = true
				break
			end
		end
	end

	for i = 1, 10, 1 do
		task.wait(0.5)

		if timechanging == false then
			print("not changing")
			checkTime()
		else
			checkLightingTime()
		end
	end

	assert(timechanging, "Time is not changing. No day/night script?")
	assert(correctDayTime >= 50, "Light is on during the day")
	assert(correctNightTime >= 50, "Light is not on at night")
end

return eval
