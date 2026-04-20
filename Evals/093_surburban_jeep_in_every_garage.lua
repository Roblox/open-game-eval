--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "093_surburban_jeep_in_every_garage",
	prompt = {
		{
			{
				role = "user",
				content = [[Place a copy of the jeep in every garage.]],
				request_id = "s20250825_023",
			},
		},
	},
	place = "surburban.rbxl",
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local Workspace = game:GetService("Workspace")
local InitalState = Workspace:GetDescendants()
local CS = game:GetService("CollectionService")

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

	local previousAddedJeeps: { Model } = CS:GetTagged("AddedJeep")
	for i, v in previousAddedJeeps do
		v:Destroy()
	end
end

eval.reference = function()
	local garageFrames: { Model } = {}
	local jeep = workspace:FindFirstChild("Jeep")
	for i, v in Workspace:GetDescendants() do
		if v:IsA("Model") and v.Name == "GarageFrame" then
			table.insert(garageFrames, v)
		end
	end

	for i, v in garageFrames do
		local newJeep = jeep:Clone()
		newJeep.Parent = Workspace
		newJeep:PivotTo(v:GetPivot() + Vector3.yAxis * -3)
		newJeep:AddTag("AddedJeep")
	end
end

eval.check_scene = function()
	local currentState = Workspace:GetDescendants()
	local garages: { model } = {}
	local garageJeepMap: { [Model]: Model } = {}

	local function GetGarages()
		for i, v in currentState do
			if v:IsA("Model") and v.Name == "GarageFrame" then
				table.insert(garages, v)
			end
		end
		return garages
	end

	local function GetClosestGarage(jeep: Model): Model
		local closestDistance: number = math.huge
		local closestGarage: Model = nil

		for i, garage in garages do
			local distance = (jeep:GetPivot().Position - garage:GetPivot().Position).Magnitude
			if distance < closestDistance then
				closestDistance = distance
				closestGarage = garage
			end
		end

		local occupyingJeep: Model = garageJeepMap[closestGarage]
		assert(occupyingJeep == nil, "Garage already has an occupying jeep!")
		garageJeepMap[closestGarage] = jeep
		return closestGarage
	end

	local function IsJeepInGarage(jeep: Model, garage: Model)
		local params: OverlapParams = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { jeep }
		local garageBoundFrame, garageBoundSize = garage:GetBoundingBox()
		local partsInBounds = Workspace:GetPartBoundsInBox(garageBoundFrame, garageBoundSize, params)
		return #partsInBounds > 0
	end

	GetGarages()

	local diff = utils_he.table_difference(InitalState, currentState)

	assert(#diff > 0, "No objects were added!")

	for i, v: Instance in diff do
		if v:IsA("Model") and v.Name == "Jeep" then
			local closestGarage = GetClosestGarage(v)
			local inGarage = IsJeepInGarage(v, closestGarage)
			assert(inGarage == true, "Jeep was not detected within it's closest garage...")
		end
	end
end

eval.check_game = function() end

return eval
