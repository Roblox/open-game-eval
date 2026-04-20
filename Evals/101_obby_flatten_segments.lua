--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "101_obby_flatten_segments",
	prompt = {
		{
			{
				role = "user",
				content = [[Flatten all obby segments within a consistent y axis]],
				request_id = "s20250825_031",
			},
		},
	},
	place = "classic_obby.rbxl",
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
	for _, obj in workspace:GetDescendants() do
		if obj:IsA("BasePart") and obj.Name ~= "TrapPart" and not obj:IsA("SpawnLocation") then
			obj.CFrame = CFrame.new(obj.CFrame.X, 1, obj.CFrame.Z)
		elseif obj:IsA("BasePart") and obj.Name == "TrapPart" or obj:IsA("SpawnLocation") then
			obj.CFrame = CFrame.new(obj.CFrame.X, 2, obj.CFrame.Z)
			--why is the above line changing oreintation
			obj.CFrame = CFrame.new(obj.CFrame.X, 2, obj.CFrame.Z) * CFrame.Angles(0, math.rad(90), 0)
		end
	end
end

eval.check_scene = function()
	local baseYPositions = {}
	local offset1StudPositions = {}

	for _, obj in workspace:GetDescendants() do
		if
			obj:IsA("BasePart")
			and obj.Name ~= "TrapPart"
			and not obj:IsA("SpawnLocation")
			and not obj:IsA("Terrain")
		then
			print(obj.Name, obj.Position.Y)
			table.insert(baseYPositions, obj.Position.Y)
		elseif
			obj:IsA("BasePart") and obj.Name == "TrapPart" or obj:IsA("SpawnLocation") and not obj:IsA("Terrain")
		then
			table.insert(offset1StudPositions, obj.Position.Y)
		end
	end

	--check if all the values in baseYpositions are the same
	assert(baseYPositions[1], "No Y position were found for the segments")
	local baseY = baseYPositions[1]
	for _, y in baseYPositions do
		if y ~= baseY then
			print(baseY)
			assert(false, "Not all segments are on the same axis")
		end
	end

	for _, offset in offset1StudPositions do
		if offset ~= baseY + 1 then
			assert(false, "offset parts are not offset or are offset incorrectly")
		end
	end
end

eval.check_game = function() end

return eval
