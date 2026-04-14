--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "091_surburban_fix_grass_in_house",
	prompt = {
		{
			{
				role = "user",
				content = [[Fix the grass in the floor of the house named 'Double Story Urban House' which shouldnt be there]],
				request_id = "s20250825_021",
			},
		},
	},
	place = "surburban.rbxl",
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
	local terrain = game:GetService("Workspace").Terrain
	local house = game:GetService("Workspace")["Double Story Urban House"]
	local region3List = {}
	for _, floor in house:GetDescendants() do
		if floor:IsA("BasePart") then
			if floor.Name == "Floor" or floor.Parent.Name == "FrontPorch" then
				local sizeOffset = Vector3.new(3 + floor.Size.X / 2, 10, 3 + floor.Size.Z / 2)
				local region3 = Region3.new(floor.Position - sizeOffset, floor.Position + sizeOffset):ExpandToGrid(4)
				table.insert(region3List, region3)
			end
		end
	end
	for _, region3 in region3List do
		terrain:ReplaceMaterial(region3, 4, Enum.Material.Grass, Enum.Material.LeafyGrass)
	end
end

eval.check_scene = function()
	local terrain = game:GetService("Workspace").Terrain
	local house = game:GetService("Workspace")["Double Story Urban House"]
	local region3List = {}
	for _, floor in house:GetDescendants() do
		if floor:IsA("BasePart") then
			if floor.Name == "Floor" or floor.Parent.Name == "FrontPorch" then
				local sizeOffset = Vector3.new(2 + floor.Size.X / 2, 6, 2 + floor.Size.Z / 2)
				local region3 = Region3.new(floor.Position - sizeOffset, floor.Position + sizeOffset):ExpandToGrid(4)
				table.insert(region3List, region3)
			end
		end
	end
	for _, region3 in region3List do
		local materials = terrain:ReadVoxels(region3, 4, Enum.Material.Grass, Enum.Material.LeafyGrass)
		for _, info in materials do
			if type(info) ~= "vector" then
				for _, voxelList in info do
					for _, voxel in voxelList do
						assert(voxel ~= Enum.Material.Grass, "Grass still found under house")
					end
				end
			end
		end
	end
end

eval.check_game = function() end

return eval
