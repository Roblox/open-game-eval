--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "085_platformer_rosphere_hover",
	prompt = {
		{
			{
				role = "user",
				content = [[Can you make the Rosphere have a hovering effect?]],
				request_id = "s20250825_015",
			},
		},
	},
	place = "platformer.rbxl",
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
	local rosphereModel = game.Workspace:FindFirstChild("LevelArt"):FindFirstChild("RoSphere")
	local newScript = Instance.new("Script")
	newScript.Source = [[
local rosphereModel = script.Parent

while true do
	rosphereModel:PivotTo(rosphereModel:GetPivot() * CFrame.new(0, 1, 0))
	wait(0.1)
	rosphereModel:PivotTo(rosphereModel:GetPivot() * CFrame.new(0, -1, 0))
	wait(0.1)
end
	]]
	-- newScript.RunContext = Enum.RunContext.Client
	newScript.Parent = rosphereModel
	newScript.Enabled = false
	task.wait()
	newScript.Enabled = true
end

eval.check_scene = function() end

eval.check_game = function()
	local rosphereModel = game.Workspace:WaitForChild("LevelArt"):WaitForChild("RoSphere")
	local goingDown = false
	local goingUp = false
	local score = 0
	local lastY = rosphereModel:GetPivot().Position.Y
	for i = 1, 600, 1 do
		if math.floor(score / 2) >= 3 then
			break
		end
		task.wait()
		local currentY = rosphereModel:GetPivot().Position.Y
		if currentY > lastY then
			goingUp = true
		elseif currentY < lastY then
			goingDown = true
		end
		if currentY > lastY and goingDown then
			goingDown = false
			goingUp = true
			score += 1
		elseif currentY < lastY and goingUp then
			goingUp = false
			goingDown = true
			score += 1
		end
		lastY = currentY
	end
	local fullHoverTimes = math.floor(score / 2)

	assert(fullHoverTimes >= 3, "Roblonk is not hovering")
end

return eval
