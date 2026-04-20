--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
if LoadedCode:FindFirstChild("EvalUtils") then
	local types = require(LoadedCode.EvalUtils.types)
	local utils_runs = require(LoadedCode.EvalUtils.utils_runs)
	local utils_he = require(LoadedCode.EvalUtils.utils_he)
	local lib = require(LoadedCode.EvalUtils.lib)
else
	local types = require(game.LoadedCode.types)
end
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
	scenario_name = "108_racing_fix_getdriversinpart",
	prompt = {
		{
			{
				role = "user",
				content = [[{"role":"user","content":"Fix the error: getDriversInPart is not a valid member of ModuleScript "ServerScriptService.Racing.RaceManager""}]],
				
			}
		}
	},
	place = "racing.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	}
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

	local script = game:GetService('ServerScriptService'):FindFirstChild('Racing'):FindFirstChild('RaceManager'):FindFirstChild('getDriversInPart')

	if script then
		script:Destroy()
	end

end

eval.reference = function()
	local RaceManager = game:GetService('ServerScriptService'):FindFirstChild('Racing'):FindFirstChild("RaceManager")

	local getDriversInPartScript = Instance.new("ModuleScript")

	getDriversInPartScript.Source = [[
local Players = game:GetService("Players")

local function isInBounds(point: Vector3, boundsCframe: CFrame, boundsSize: Vector3): boolean
	local offset = boundsCframe:PointToObjectSpace(point)
	return math.abs(offset.X) <= boundsSize.X / 2
		and math.abs(offset.Y) <= boundsSize.Y / 2
		and math.abs(offset.Z) <= boundsSize.Z / 2
end

-- Return all the players inside a specified part who are currently sitting in a VehicleSeat
local function getDriversInPart(part: BasePart): { Player }
	local drivers = {}

	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not (player.Character and player.Character.PrimaryPart) then
			continue
		end

		if isInBounds(player.Character.PrimaryPart.Position, part.CFrame, part.Size) then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then
				continue
			end
			if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
				table.insert(drivers, player)
			end
		end
	end

	return drivers
end

return getDriversInPart
	]]
	getDriversInPartScript.Name = "getDriversInPart"
	getDriversInPartScript.Parent = RaceManager
end

eval.check_scene = function()
	-- Test #1: Verify that the "getDriversInPart" function exists.
	local RaceManager = game:GetService('ServerScriptService'):FindFirstChild('Racing'):FindFirstChild("RaceManager")
	assert(RaceManager:FindFirstChild('getDriversInPart'), "getDriversInPart function not found")

  -- Test #2: Verify that "getDriversInPart" is a modlue script.
  local getDriversInPart = RaceManager:FindFirstChild('getDriversInPart');
  assert(getDriversInPart:IsA("ModuleScript"), "getDriversInPart should be a module script")
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	-- Replicate the spawnCar function from "ServerScriptService.CarSpawning.spawnCar"
	-- in order to get the spawned car back.
	local function spawnCar(location: CFrame, owner: Player?)
		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local carTemplate = ReplicatedStorage.Car
		local CarConstants = require(carTemplate.Scripts.Constants)

		local car = carTemplate:Clone()
		car:PivotTo(location)

		-- Set the car's owner
		if owner then
			-- Since instance references can't be stored in attributes, the car owner is stored by UserId
			car:SetAttribute(CarConstants.CAR_OWNER_ATTRIBUTE, owner.UserId)
		end

		car.Parent = workspace
		return car
	end

	-- Setup environment for testing --
	local CollectionService = game:GetService("CollectionService")

	local Players = game:GetService("Players")
	local player = #Players:GetPlayers() > 0 and Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	assert(player, "No player found")

	-- Wait for character to be available
	local character = player.Character or player.CharacterAdded:Wait()
	assert(character, "LocalPlayer has no character")

	-- Wait for character to be fully loaded
	local humanoid = character:WaitForChild("Humanoid", 5)
	assert(humanoid, "Character has no Humanoid")

	---- Get race container using CollectionService
	local raceContainers = CollectionService:GetTagged("Race")
	assert(#raceContainers > 0, "No race containers found with 'Race' tag")
	local raceContainer = raceContainers[1]

	local startingArea = raceContainer:FindFirstChild("StartingArea")


	local RaceManager = game:GetService('ServerScriptService'):FindFirstChild('Racing'):FindFirstChild("RaceManager")
	-- Duplicating assertion from check_scene to get a meaningful error message when reference code has not been added.
	assert(RaceManager:FindFirstChild('getDriversInPart'), "getDriversInPart function not found")

	local getDriversInPart = require(RaceManager:FindFirstChild('getDriversInPart'));

	-- Test #1: Ensure that no players are in the race before adding the car to the startingArea.
	task.wait(0.5)
	assert(#getDriversInPart(startingArea) == 0, "There should not be any players in the race")

	-- Test #2: Ensure that there is 1 player in the race after adding a driver to the starting area.
	-- Spawn a temporary car and make the player sit in it.
	local car = spawnCar(startingArea.CFrame * CFrame.new(0, 1, 0), player)
	car.DriverSeat:Sit(humanoid)

	task.wait(0.5)
	assert(#getDriversInPart(startingArea) == 1, "There should be one player in the race")

	print("Server: All tests passed!")
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	-- No client tests, everything is tested on the server.
end)

return eval
