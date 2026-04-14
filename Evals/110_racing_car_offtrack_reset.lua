--!strict

local function loadDependencies(requested)
	local LoadedCode = game:FindFirstChild("LoadedCode")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local EvalUtils = LoadedCode:FindFirstChild("EvalUtils") or ReplicatedStorage:FindFirstChild("EvalUtils", true)
	if not EvalUtils then
		EvalUtils = Instance.new("Folder")
		EvalUtils.Name = "EvalUtils"
		EvalUtils.Archivable = true
		EvalUtils.Parent = LoadedCode
	end
	local modules = {}
	if requested then
		for _,request in requested do
			modules[request] = {}
		end
	else
		modules = {
			types = {},
			utils_he = {},
			utils_runs = {},
			utils_checks = {},
			lib = {}
		}
	end

	for moduleName,_ in modules do
		local instance = EvalUtils:FindFirstChild(moduleName) or LoadedCode:FindFirstChild(moduleName) or ReplicatedStorage:FindFirstChild(moduleName, true)
		if not instance then
			warn("Failed to find EvalUtils module: " .. moduleName)
		else    
			if(instance.Parent ~= EvalUtils) then
				instance = instance:Clone()
				instance.Archivable = false
				instance.Parent = EvalUtils
			end
		end
		modules[moduleName] = instance
	end

	if EvalUtils.Parent ~= LoadedCode then
		EvalUtils.Archivable = true
		EvalUtils = EvalUtils:Clone()
		EvalUtils.Parent = LoadedCode
	end
	for moduleName,module in modules do
		modules[moduleName] = require(module)
	end

	return modules
end
local dependencies = loadDependencies()
local types = dependencies.types
local utils_he = dependencies.utils_he
local utils_runs = dependencies.utils_runs
local utils_checks = dependencies.utils_checks
local lib = dependencies.lib

local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
	scenario_name = "pilot_028",
	prompt = {
		{
			{
				role = "user",
				content = [[Add a 'reset' functionality to the game that detects whether the car is upside down or is off-track for 5s. The reset functionality should teleport the car to the starting position on the track with the player.]],
				request_id = "pilot_028"
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
	utils_runs.createPlayerScripts()

end

eval.reference = function()
	local ServerScriptService = game:GetService("ServerScriptService")

	local resetScript = Instance.new("Script")
	resetScript.Name = "CarResetSystem"
	resetScript.Source = [[
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")
		local Workspace = game:GetService("Workspace")

		local UPSIDE_DOWN_THRESHOLD = 0.5
		local OFF_TRACK_TIME_THRESHOLD = 5
		local UPSIDE_DOWN_TIME_THRESHOLD = 5
		local STUCK_TIME_THRESHOLD = 5
		local STUCK_VELOCITY_THRESHOLD = 2
		local RESET_COOLDOWN = 3
		local TRACK_SEARCH_RADIUS = 30

		local startCFrame = CFrame.new(0, 5, 0)

		local function findStartingPosition()
			local startingArea = Workspace:FindFirstChild("StartingArea", true)
			if startingArea then
				if startingArea:IsA("BasePart") then
					return CFrame.new(startingArea.Position + Vector3.new(0, 5, 0))
				elseif startingArea:IsA("Model") and startingArea.PrimaryPart then
					return CFrame.new(startingArea.PrimaryPart.Position + Vector3.new(0, 5, 0))
				end
			end
			
			local potentialStarts = {"Start", "StartLine", "StartPosition", "Spawn"}
			for _, name in ipairs(potentialStarts) do
				local found = Workspace:FindFirstChild(name, true)
				if found then
					if found:IsA("BasePart") then
						return CFrame.new(found.Position + Vector3.new(0, 5, 0))
					elseif found:IsA("Model") and found.PrimaryPart then
						return CFrame.new(found.PrimaryPart.Position + Vector3.new(0, 5, 0))
					end
				end
			end
			
			local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
			if spawnLocation then
				return CFrame.new(spawnLocation.Position + Vector3.new(0, 5, 0))
			end
			
			return CFrame.new(0, 5, 0)
		end

		startCFrame = findStartingPosition()

		local function findTrackParts()
			local trackParts = {}
			local roadKeywords = {"track", "road", "path", "asphalt", "pavement", "street", "highway", "lane"}
			
			for _, descendant in ipairs(Workspace:GetDescendants()) do
				if descendant:IsA("BasePart") then
					local name = descendant.Name:lower()
					for _, keyword in ipairs(roadKeywords) do
						if name:find(keyword) then
							table.insert(trackParts, descendant)
							break
						end
					end
				end
			end
			return trackParts
		end

		local trackParts = findTrackParts()
		local trackPartsSet = {}
		for _, part in ipairs(trackParts) do
			trackPartsSet[part] = true
		end

		local function isPositionOnTrack(position, excludeModel)
			local raycastParams = RaycastParams.new()
			if excludeModel then
				raycastParams.FilterDescendantsInstances = {excludeModel}
				raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			end
			
			local rayOrigin = position + Vector3.new(0, 5, 0)
			local rayDirection = Vector3.new(0, -20, 0)
			local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			
			if result and result.Instance then
				local hitPart = result.Instance
				local hitName = hitPart.Name:lower()
				
				-- Check if we hit a known track part
				if trackPartsSet[hitPart] then
					return true
				end
				
				-- Check for road keywords - definitely on track
				local roadKeywords = {"track", "road", "path", "asphalt", "pavement", "street"}
				for _, keyword in ipairs(roadKeywords) do
					if hitName:find(keyword) then
						return true
					end
				end
				
				-- Check for off-road keywords - definitely off track
				local offRoadKeywords = {"grass", "stone", "rock", "dirt", "sand", "gravel", "terrain", "ground"}
				for _, keyword in ipairs(offRoadKeywords) do
					if hitName:find(keyword) then
						return false
					end
				end
				
				-- If we hit something but it's not explicitly off-road, assume on-track
				-- This prevents false positives when track surfaces have generic names
				return true
			end
			
			-- No raycast hit - use distance from start as fallback
			if #trackParts == 0 then
				return (position - startCFrame.Position).Magnitude < 50
			end
			
			-- Raycast didn't hit anything - likely in the air or over void
			return false
		end

		local function getPlayerVehicle(player)
			local character = player.Character
			if not character then return nil end
			
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if not humanoid then return nil end
			
			if humanoid.SeatPart and humanoid.SeatPart:IsA("VehicleSeat") then
				local vehicle = humanoid.SeatPart:FindFirstAncestorWhichIsA("Model")
				if vehicle and vehicle.PrimaryPart then
					return vehicle
				end
			end
			
			return nil
		end

		local function isVehicleUpsideDown(vehicle)
			if not vehicle or not vehicle.PrimaryPart then return false end
			local upVector = vehicle.PrimaryPart.CFrame.UpVector
			return upVector.Y < UPSIDE_DOWN_THRESHOLD
		end

		local function isVehicleStuck(vehicle)
			if not vehicle or not vehicle.PrimaryPart then return false end
			local velocity = vehicle.PrimaryPart.AssemblyLinearVelocity
			return velocity.Magnitude < STUCK_VELOCITY_THRESHOLD
		end

		local function resetVehicle(player, vehicle)
			local root = vehicle.PrimaryPart
			if not root then return end

			-- Briefly anchor the vehicle.
			-- This overrides the Client's physics network ownership, forcing
			-- the Server's position update to be accepted immediately.
			local oldAnchored = root.Anchored
			root.Anchored = true
			
			vehicle:PivotTo(startCFrame)
			
			root.AssemblyLinearVelocity = Vector3.new()
			root.AssemblyAngularVelocity = Vector3.new()
			
			task.wait()
			
			root.Anchored = oldAnchored
			
			local character = player.Character
			if character then
				local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
				if humanoidRootPart then
					character:PivotTo(startCFrame * CFrame.new(0, 3, 0))
					humanoidRootPart.AssemblyLinearVelocity = Vector3.new()
					humanoidRootPart.AssemblyAngularVelocity = Vector3.new()
				end
			end
		end

		local playerData = {}
		local configuredVehicles = {}

		-- Configure the built-in Redresser to wait longer than our threshold
		local function configureVehicleRedresser(vehicle)
			if configuredVehicles[vehicle] then return end
			local redress = vehicle:FindFirstChild("Redress")
			if redress then
				redress:SetAttribute("maxTimeFlipped", 6) -- 6s > our 5s threshold
			end
			configuredVehicles[vehicle] = true
		end

		RunService.Heartbeat:Connect(function(deltaTime)
			for _, player in ipairs(Players:GetPlayers()) do
				local vehicle = getPlayerVehicle(player)
				
				if not playerData[player] then
					playerData[player] = {
						upsideDownTime = 0,
						offTrackTime = 0,
						stuckTime = 0,
						lastResetTime = 0
					}
				end
				
				-- Configure Redresser when player enters a vehicle
				if vehicle then
					configureVehicleRedresser(vehicle)
				end
				
				local data = playerData[player]
				local currentTime = tick()
				
				if not vehicle or (currentTime - data.lastResetTime) < RESET_COOLDOWN then
					data.upsideDownTime = 0
					data.offTrackTime = 0
					data.stuckTime = 0
					continue
				end
				
				local upsideDown = isVehicleUpsideDown(vehicle)
				if upsideDown then
					data.upsideDownTime = data.upsideDownTime + deltaTime
				else
					data.upsideDownTime = 0
				end
				
				local onTrack = false
				if vehicle.PrimaryPart then
					onTrack = isPositionOnTrack(vehicle.PrimaryPart.Position, vehicle)
				end
				
				if not onTrack then
					data.offTrackTime = data.offTrackTime + deltaTime
				else
					data.offTrackTime = 0
				end
				
				local stuck = isVehicleStuck(vehicle)
				if stuck and not onTrack then
					data.stuckTime = data.stuckTime + deltaTime
				else
					data.stuckTime = 0
				end
				
				local shouldReset = false
				
				if data.upsideDownTime >= UPSIDE_DOWN_TIME_THRESHOLD then
					shouldReset = true
				elseif data.stuckTime >= STUCK_TIME_THRESHOLD then
					shouldReset = true
				end
				
				if shouldReset then
					resetVehicle(player, vehicle)
					data.lastResetTime = currentTime
					data.upsideDownTime = 0
					data.offTrackTime = 0
					data.stuckTime = 0
				end
			end
		end)

		Players.PlayerRemoving:Connect(function(player)
			playerData[player] = nil
		end)
	]]

	resetScript.Parent = ServerScriptService
end

eval.check_scene = function()

end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")

	-- Find starting position for the car
	local startCFrame = CFrame.new(0, 5, 0)
	local startingArea = Workspace:FindFirstChild("StartingArea", true)
	if startingArea then
		if startingArea:IsA("BasePart") then
			startCFrame = CFrame.new(startingArea.Position + Vector3.new(0, 5, 0))
		elseif startingArea:IsA("Model") and startingArea.PrimaryPart then
			startCFrame = CFrame.new(startingArea.PrimaryPart.Position + Vector3.new(0, 5, 0))
		end
	else
		local potentialStarts = {"Start", "StartLine", "StartPosition", "Spawn"}
		for _, name in ipairs(potentialStarts) do
			local found = Workspace:FindFirstChild(name, true)
			if found then
				if found:IsA("BasePart") then
					startCFrame = CFrame.new(found.Position + Vector3.new(0, 5, 0))
				elseif found:IsA("Model") and found.PrimaryPart then
					startCFrame = CFrame.new(found.PrimaryPart.Position + Vector3.new(0, 5, 0))
				end
				break
			end
		end

		local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
		if spawnLocation and startCFrame == CFrame.new(0, 5, 0) then
			startCFrame = CFrame.new(spawnLocation.Position + Vector3.new(0, 5, 0))
		end
	end

	-- Spawn the actual car from ReplicatedStorage at an OFFSET position
	-- This ensures the test properly validates that reset teleports the car back to start
	local carTemplate = ReplicatedStorage:FindFirstChild("Car")
	assert(carTemplate, "Car template not found in ReplicatedStorage")

	-- Offset the spawn position 100 studs away from starting area
	local testSpawnCFrame = startCFrame * CFrame.new(100, 0, 0)

	local car = carTemplate:Clone()
	car:PivotTo(testSpawnCFrame)
	car.Parent = Workspace
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")
	local RunService = game:GetService("RunService")

	local player = Players.LocalPlayer
	assert(player, "LocalPlayer not found")

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 10)
	assert(humanoid, "Player humanoid not found")

	task.wait(1)

	-- Helper to find vehicle
	local function findVehicle()
		for _, model in ipairs(Workspace:GetDescendants()) do
			if model:IsA("Model") and model.PrimaryPart then
				local vehicleSeat = model:FindFirstChildWhichIsA("VehicleSeat", true)
				if vehicleSeat and not vehicleSeat.Occupant then
					return model, vehicleSeat
				end
			end
		end
		return nil, nil
	end

	-- Wait for the car spawned by serverCheck to replicate
	local vehicle, vehicleSeat
	for i = 1, 5 do
		vehicle, vehicleSeat = findVehicle()
		if vehicle then break end
		task.wait(1)
	end

	assert(vehicle and vehicleSeat, "No vehicle found to test with (ServerCheck failed to spawn one).")

	assert(not vehicle.PrimaryPart.Anchored, "Test failed: Vehicle is anchored and cannot be moved")

	-- Calculate expected Start Position
	local startingPosition = Vector3.new(0, 5, 0)
	local startingArea = Workspace:FindFirstChild("StartingArea", true)
	if startingArea then
		if startingArea:IsA("BasePart") then
			startingPosition = startingArea.Position + Vector3.new(0, 5, 0)
		elseif startingArea:IsA("Model") and startingArea.PrimaryPart then
			startingPosition = startingArea.PrimaryPart.Position + Vector3.new(0, 5, 0)
		end
	else
		-- Fallback logic matches Reference
		local potentialStarts = {"Start", "StartLine", "StartPosition", "Spawn"}
		for _, name in ipairs(potentialStarts) do
			local found = Workspace:FindFirstChild(name, true)
			if found then
				if found:IsA("BasePart") then
					startingPosition = found.Position + Vector3.new(0, 5, 0)
				elseif found:IsA("Model") and found.PrimaryPart then
					startingPosition = found.PrimaryPart.Position + Vector3.new(0, 5, 0)
				end
				break
			end
		end

		if startingPosition == Vector3.new(0, 5, 0) then
			local spawnLocation = Workspace:FindFirstChildWhichIsA("SpawnLocation", true)
			if spawnLocation then
				startingPosition = spawnLocation.Position + Vector3.new(0, 5, 0)
			end
		end
	end

	-- Teleport Character close to vehicle using PivotTo
	character:PivotTo(vehicle:GetPivot() + Vector3.new(0, 5, 0))
	task.wait(0.5)

	-- Sit player in the vehicle
	vehicleSeat:Sit(humanoid)
	task.wait(1)

	assert(humanoid.SeatPart == vehicleSeat, "Could not sit player in vehicle - test cannot proceed")

	-- Record initial position (car is spawned off-track, 100 studs from start)
	local initialPosition = vehicle.PrimaryPart.Position
	local initialDistFromStart = (initialPosition - startingPosition).Magnitude
	
	-- Verify car is actually off-track 
	assert(initialDistFromStart > 50, "Car should be spawned off-track for this test, but is too close to start")

	-- Flip vehicle upside down using PivotTo
	local currentPivot = vehicle:GetPivot()
	local flippedPivot = currentPivot * CFrame.Angles(math.pi, 0, 0)
	vehicle:PivotTo(flippedPivot)

	-- Verify upside down
	local upVector = vehicle.PrimaryPart.CFrame.UpVector
	assert(upVector.Y < 0.5, "Vehicle was not flipped upside down properly")

	local resetSuccess = false
	local checkStartTime = tick()

	-- Wait up to 10 seconds for the reset (5s threshold + buffer)
	while (tick() - checkStartTime) < 10 do
		task.wait(0.5)

		-- Check if vehicle moved to start (using 80 stud tolerance for spawn variation)
		local dist = (vehicle.PrimaryPart.Position - startingPosition).Magnitude
		if dist < 80 then
			resetSuccess = true
			break
		end
	end

	assert(resetSuccess, "Vehicle did not reset to the expected starting position. Found at: " .. tostring(vehicle.PrimaryPart.Position) .. " Expected near: " .. tostring(startingPosition))
end)

return eval