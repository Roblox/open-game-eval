--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "099_city_add_cars",
	prompt = {
		{
			{
				role = "user",
				content = [[Add cars on the road]],
				request_id = "s20250825_029",
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
	local workspace = game:GetService("Workspace")
	local car = workspace.City_Template.Vehicles["Sedan (red)"]
	local carCount = 5
	local streetMeshes = workspace.City_Template.Streets_Sidewalks.StreetMeshes
	local streetList = {}
	for _, street in streetMeshes:GetChildren() do
		table.insert(streetList, street)
	end
	for i = 1, carCount do
		local index = math.random(1, #streetList)
		local randomStreet = streetList[index]
		local randomStreetPos = streetList[index]:GetBoundingBox()
		local newCar = car:Clone()
		newCar:PivotTo(CFrame.new(randomStreetPos.X, car:GetPivot().Y, randomStreetPos.Z))
		newCar.Parent = workspace
		table.remove(streetList, index)
	end
end

eval.check_scene = function()
	--There are already 2 cars in the map on the road/street, so checking if > 2
	local workspace = game:GetService("Workspace")
	local streetMeshes = workspace.City_Template.Streets_Sidewalks.StreetMeshes
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { streetMeshes }
	local carCount = 0
	for _, street in streetMeshes:GetDescendants() do
		if street:IsA("BasePart") and string.match(street.Name, "road") then
			local cframe = street.CFrame
			local size = street.Size
			local carParts = workspace:GetPartBoundsInBox(cframe, size + Vector3.new(0, 20, 0), overlapParams)
			for _, p in carParts do
				if p:IsA("VehicleSeat") then
					carCount += 1
				end
			end
		end
	end
	assert(carCount > 2, "No new cars were added to the roads")
end

eval.check_game = function() end

return eval
