--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "102_city_spawn_on_tallest_building",
	prompt = {
		{
			{
				role = "user",
				content = [[Set the spawn for the players on top of the tallest building]],
				request_id = "s20250825_032",
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
	local highestPoint = Vector3.new(0, -100, 0)
	local spawnPart = game:GetService("Workspace").City_Template.SpawnLocation
	local getBuildings = game:GetService("Workspace").City_Template.CityTemplateBuildings:GetDescendants()
	for _, p in getBuildings do
		if p:IsA("BasePart") then
			local pos = p.Position + Vector3.new(0, p.Size.Y / 2, 0)
			if pos.Y > highestPoint.Y then
				highestPoint = pos
			end
		end
	end
	spawnPart.Position = highestPoint + Vector3.new(0, spawnPart.Size.Y / 2, 0)
end

eval.check_scene = function()
	local highestPoint = Vector3.new(0, -100, 0)
	local spawnPart = game:GetService("Workspace").City_Template.SpawnLocation
	local getBuildings = game:GetService("Workspace").City_Template.CityTemplateBuildings:GetDescendants()
	for _, p in getBuildings do
		if p:IsA("BasePart") then
			local pos = p.Position + Vector3.new(0, p.Size.Y / 2, 0)
			if pos.Y > highestPoint.Y then
				highestPoint = pos
			end
		end
	end
	assert(spawnPart.Position.Y >= highestPoint.Y, "Spawn is not set to the top of the tallest building")
end

eval.check_game = function() end

return eval
