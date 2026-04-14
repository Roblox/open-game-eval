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
		for _, request in requested do
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
	for moduleName, _ in modules do
		local instance = EvalUtils:FindFirstChild(moduleName) or LoadedCode:FindFirstChild(moduleName) or ReplicatedStorage:FindFirstChild(moduleName, true)
		if not instance then
			warn("Failed to find EvalUtils module: " .. moduleName)
		else
			if instance.Parent ~= EvalUtils then
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
	for moduleName, module in modules do
		modules[moduleName] = require(module)
	end
	return modules
end

local dependencies = loadDependencies()
local types = dependencies.types
local utilsHe = dependencies.utils_he
local utilsRuns = dependencies.utils_runs

local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
	scenario_name = "pilot_029",
	prompt = {{{
		role = "user",
		content = [[If the player is going in the wrong direction in the race, show a warning on their screen that says 'WRONG DIRECTION'.]],
		request_id = "pilot_029"
	}}},
	place = "racing.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	}
}

local selectionContextJson = "[]"
local tableSelectionContext = HttpService:JSONDecode(selectionContextJson)
local testRemoteName = "EvalTestWrongDirectionEvent"

eval.setup = function()
	utilsRuns.createPlayerScripts()
end

eval.reference = function()
	local StarterGui = game:GetService("StarterGui")
	local raceGuiTemplate = StarterGui:FindFirstChild("RaceGui")
	if not raceGuiTemplate then return end

	local existing = raceGuiTemplate:FindFirstChild("WrongDirectionWarning")
	if existing then existing:Destroy() end

	local warningLabel = Instance.new("TextLabel")
	warningLabel.Name = "WrongDirectionWarning"
	warningLabel.Size = UDim2.fromScale(0.5, 0.15)
	warningLabel.Position = UDim2.fromScale(0.5, 0.3)
	warningLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	warningLabel.BackgroundTransparency = 1
	warningLabel.Text = "WRONG DIRECTION"
	warningLabel.TextColor3 = Color3.fromRGB(255, 50, 50)
	warningLabel.TextScaled = true
	warningLabel.Font = Enum.Font.GothamBold
	warningLabel.Visible = false
	warningLabel.Parent = raceGuiTemplate

	local scriptSource = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local getCheckpoints = require(ReplicatedStorage.Utility.getCheckpoints)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)

local player = Players.LocalPlayer
local playerGui = player.PlayerGui
local raceGui = playerGui:WaitForChild("RaceGui")
local warningLabel = raceGui:WaitForChild("WrongDirectionWarning")

local remotes = ReplicatedStorage.Remotes
local joinRaceRemote = remotes.JoinRace
local leaveRaceRemote = remotes.LeaveRace
local showCountdownRemote = remotes.ShowCountdown

local enabled = false
local raceStarted = false
local connections = {}
local sampledPoints = {}
local SAMPLE_COUNT = 100
local SPEED_THRESHOLD = 5
local DOT_THRESHOLD = -0.3
local HORIZONTAL = Vector3.new(1, 0, 1)

local function catmullRom(t: number, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3): Vector3
    local t2 = t * t
    local t3 = t2 * t
    return 0.5 * ((2 * p1) + (-p0 + p2) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 + (-p0 + 3 * p1 - 3 * p2 + p3) * t3)
end

local function catmullRomTangent(t: number, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3): Vector3
    local t2 = t * t
    return 0.5 * ((-p0 + p2) + (4 * p0 - 10 * p1 + 8 * p2 - 2 * p3) * t + (-3 * p0 + 9 * p1 - 9 * p2 + 3 * p3) * t2)
end

local function sampleSpline(checkpoints: {BasePart})
    table.clear(sampledPoints)
    local n = #checkpoints
    for i = 1, n do
        local p0 = checkpoints[((i - 1 - 1) % n) + 1].Position
        local p1 = checkpoints[i].Position
        local p2 = checkpoints[(i % n) + 1].Position
        local p3 = checkpoints[((i + 1) % n) + 1].Position
        local samplesPerSegment = math.ceil(SAMPLE_COUNT / n)
        for j = 0, samplesPerSegment - 1 do
            local t = j / samplesPerSegment
            local position = catmullRom(t, p0, p1, p2, p3)
            local tangent = catmullRomTangent(t, p0, p1, p2, p3)
            tangent = (tangent * HORIZONTAL).Unit
            table.insert(sampledPoints, {position = position, tangent = tangent})
        end
    end
end

local function getNearestTangent(playerPosition: Vector3): Vector3?
    if #sampledPoints == 0 then return nil end
    local nearestIndex = 1
    local nearestDistance = math.huge
    local flatPlayerPos = playerPosition * HORIZONTAL
    for i, sample in ipairs(sampledPoints) do
        local flatSamplePos = sample.position * HORIZONTAL
        local distance = (flatSamplePos - flatPlayerPos).Magnitude
        if distance < nearestDistance then
            nearestDistance = distance
            nearestIndex = i
        end
    end
    return sampledPoints[nearestIndex].tangent
end

local function getPlayerVehicle(): BasePart?
    local character = player.Character
    if not character then return nil end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end
    local seat = humanoid.SeatPart
    if not seat or not seat:IsA("VehicleSeat") then return nil end
    return seat
end

local function onRenderStepped()
    if not raceStarted then
        warningLabel.Visible = false
        return
    end
    local seat = getPlayerVehicle()
    if not seat then
        warningLabel.Visible = false
        return
    end
    local car = seat:FindFirstAncestorWhichIsA("Model")
    if not car or not car.PrimaryPart then
        warningLabel.Visible = false
        return
    end
    local velocity = car.PrimaryPart.AssemblyLinearVelocity
    local speed = velocity.Magnitude
    if speed < SPEED_THRESHOLD then
        warningLabel.Visible = false
        return
    end
    local playerPosition = car:GetPivot().Position
    local trackTangent = getNearestTangent(playerPosition)
    if not trackTangent then
        warningLabel.Visible = false
        return
    end
    local seatForward = seat.CFrame.LookVector
    local seatForward2D = (seatForward * HORIZONTAL).Unit
    local facingWrongWay = seatForward2D:Dot(trackTangent) < DOT_THRESHOLD
    local moveDirection = (velocity * HORIZONTAL).Unit
    local movingWrongWay = moveDirection:Dot(trackTangent) < DOT_THRESHOLD
    warningLabel.Visible = (facingWrongWay and movingWrongWay)
end

local function joinRace(raceContainer: Model)
    if enabled then return end
    enabled = true
    raceStarted = false
    local checkpoints = getCheckpoints(raceContainer)
    sampleSpline(checkpoints)
    table.insert(connections, RunService.RenderStepped:Connect(onRenderStepped))
end

local function leaveRace()
    if not enabled then return end
    enabled = false
    raceStarted = false
    disconnectAndClear(connections)
    table.clear(sampledPoints)
    warningLabel.Visible = false
end

local function onShowCountdown(countdown: number)
    if not enabled then return end
    task.spawn(function()
        task.wait(countdown + 0.5)
        if enabled then raceStarted = true end
    end)
end

joinRaceRemote.OnClientEvent:Connect(joinRace)
leaveRaceRemote.OnClientEvent:Connect(leaveRace)
showCountdownRemote.OnClientEvent:Connect(onShowCountdown)

task.spawn(function()
    task.wait(1)
    if CollectionService:HasTag(player, "InRace") and not enabled then
        for _, raceContainer in CollectionService:GetTagged("Race") do
            joinRace(raceContainer)
            task.wait(3)
            raceStarted = true
            break
        end
    end
end)
]]

	local existingScript = game:GetService("ReplicatedStorage"):FindFirstChild("WrongDirectionDetector")
	if existingScript then existingScript:Destroy() end

	local newScript = utilsHe.CreateScript(scriptSource, true, Enum.RunContext.Client)
	newScript.Name = "WrongDirectionDetector"
end

eval.check_scene = function() end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local CollectionService = game:GetService("CollectionService")
	local Workspace = game:GetService("Workspace")
	local Players = game:GetService("Players")

	local testRemote = ReplicatedStorage:FindFirstChild(testRemoteName)
	if not testRemote then
		testRemote = Instance.new("RemoteEvent")
		testRemote.Name = testRemoteName
		testRemote.Parent = ReplicatedStorage
	end

	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()

	local clientReadyEvent = Instance.new("BindableEvent")
	local resultEvent = Instance.new("BindableEvent")
	local clientReady = false
	testRemote.OnServerEvent:Connect(function(fromPlayer, message)
		if fromPlayer == player and message == "CLIENT_READY" then
			clientReady = true
			clientReadyEvent:Fire()
		end
	end)

	-- Blocks until client sends CHECK_DONE
	local pendingResult = nil
	local function waitForResult()
		local conn
		conn = testRemote.OnServerEvent:Connect(function(fromPlayer, message, res)
			if fromPlayer == player and message == "CHECK_DONE" then
				pendingResult = res
				conn:Disconnect()
				resultEvent:Fire()
			end
		end)
		resultEvent.Event:Wait()
		return pendingResult
	end

	local function logTest(num: number, name: string, passed: boolean)
		local status = passed and "PASS" or "FAIL"
		print(string.format("[test %d] %s: %s", num, name, status))
	end

	local HORIZONTAL = Vector3.new(1, 0, 1)

	-- Road tracing using stripes-based curve (matches debug visualization)
	local Racetrack = Workspace:FindFirstChild("Racetrack")
	local Roads = Racetrack and Racetrack:FindFirstChild("Roads")

	-- Catmull-Rom spline for path generation
	local function catmullRomSpline(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
		local t2 = t * t
		local t3 = t2 * t
		return 0.5 * (
			(2 * p1) +
			(-p0 + p2) * t +
			(2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
			(-p0 + 3 * p1 - 3 * p2 + p3) * t3
		)
	end

	-- Catmull-Rom tangent (derivative)
	local function catmullRomTangent(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: number): Vector3
		local t2 = t * t
		return 0.5 * (
			(-p0 + p2) +
			(4 * p0 - 10 * p1 + 8 * p2 - 2 * p3) * t +
			(-3 * p0 + 9 * p1 - 9 * p2 + 3 * p3) * t2
		)
	end

	-- Collect road points from stripes meshes
	local function collectRoadPoints(): {{position: Vector3, isLargeBank: boolean}}
		local roadPointsData = {}
		if not Roads then return roadPointsData end

		for _, descendant in Roads:GetDescendants() do
			if descendant:IsA("BasePart") then
				local name = descendant.Name:lower()
				if name == "stripes" or name:match("stripes$") then
					local pos = descendant.Position
					local isLargeBank = false

					local fullName = descendant:GetFullName():lower()
					local isCurvedRoad = fullName:match("bank_") or fullName:match("bend_")

					if isCurvedRoad then
						local pivotPos = descendant:GetPivot().Position
						local toPivot = (pivotPos - descendant.Position)
						local curveDir = Vector3.new(toPivot.X, 0, toPivot.Z).Unit
						local radialDir = Vector3.new(-curveDir.Z, 0, curveDir.X)

						local SMALLEST_STRIPE_SIZE = 74
						local offset = 0.8 * math.pow(math.max(0, descendant.Size.X - SMALLEST_STRIPE_SIZE), 0.75)

						local isBank = fullName:match("bank_") ~= nil
						isLargeBank = isBank and descendant.Size.X > 150

						if isBank then
							local cf = descendant.CFrame
							pos = descendant.Position - radialDir * offset
							local heightAdjust = -cf.RightVector.Y * offset
							pos = pos + Vector3.new(0, heightAdjust, 0)
						else
							pos = descendant.Position - radialDir * offset
						end
					end

					table.insert(roadPointsData, {
						position = pos,
						isLargeBank = isLargeBank
					})
				end
			end
		end
		return roadPointsData
	end

	-- Sort points by checkpoint segments
	local function sortByCheckpoints(pointsData: {{position: Vector3, isLargeBank: boolean}}, cps: {BasePart}): {{position: Vector3, isLargeBank: boolean}}
		if #pointsData == 0 or #cps < 2 then return pointsData end

		local pointDataWithSort = {}
		for _, pd in pointsData do
			local point = pd.position
			local bestSegment = 1
			local bestProgress = 0
			local bestDist = math.huge

			for i = 1, #cps do
				local cpA = cps[i].Position
				local cpB = cps[(i % #cps) + 1].Position
				local segmentVec = cpB - cpA
				local segmentLen = segmentVec.Magnitude
				if segmentLen > 0 then
					local toPoint = point - cpA
					local progress = toPoint:Dot(segmentVec) / (segmentLen * segmentLen)
					progress = math.clamp(progress, 0, 1)
					local projectedPos = cpA + segmentVec * progress
					local dist = (point - projectedPos).Magnitude

					if dist < bestDist then
						bestDist = dist
						bestSegment = i
						bestProgress = progress
					end
				end
			end

			table.insert(pointDataWithSort, {
				position = pd.position,
				isLargeBank = pd.isLargeBank,
				segment = bestSegment,
				progress = bestProgress
			})
		end

		table.sort(pointDataWithSort, function(a, b)
			if a.segment ~= b.segment then
				return a.segment < b.segment
			end
			return a.progress < b.progress
		end)

		local sorted = {}
		for _, data in pointDataWithSort do
			table.insert(sorted, {
				position = data.position,
				isLargeBank = data.isLargeBank
			})
		end
		return sorted
	end

	-- Insert midpoints between consecutive large banks
	local function insertLargeBankMidpoints(pointsData: {{position: Vector3, isLargeBank: boolean}}): {Vector3}
		local result = {}
		local n = #pointsData

		for i = 1, n do
			local current = pointsData[i]
			local nextIdx = (i % n) + 1
			local nextPoint = pointsData[nextIdx]

			table.insert(result, current.position)

			if current.isLargeBank and nextPoint.isLargeBank then
				local midpoint = (current.position + nextPoint.position) / 2
				local dir = (nextPoint.position - current.position)
				local dirXZ = Vector3.new(dir.X, 0, dir.Z)
				local distance = dirXZ.Magnitude

				if distance > 0 then
					local perpendicular = dirXZ.Unit:Cross(Vector3.yAxis)
					local outwardOffset = distance * 0.2
					midpoint = midpoint + perpendicular * outwardOffset
				end

				table.insert(result, midpoint)
			end
		end

		return result
	end

	-- Generate spline path with tangents
	local function traceRoadPath(checkpoints: {BasePart}, sampleInterval: number?): {{position: Vector3, tangent: Vector3, checkpointIndex: number}}
		local SEGMENTS_PER_SPAN = 16
		local path = {}

		local roadPointsData = collectRoadPoints()
		local sortedData = sortByCheckpoints(roadPointsData, checkpoints)
		local sortedPoints = insertLargeBankMidpoints(sortedData)

		local n = #sortedPoints
		if n < 2 then return path end

		local function wrapIndex(idx: number): number
			return ((idx - 1) % n) + 1
		end

		-- Generate spline points with tangents
		for i = 1, n do
			local p0 = sortedPoints[wrapIndex(i - 1)]
			local p1 = sortedPoints[wrapIndex(i)]
			local p2 = sortedPoints[wrapIndex(i + 1)]
			local p3 = sortedPoints[wrapIndex(i + 2)]

			-- Find which checkpoint this segment belongs to
			local checkpointIndex = 1
			local bestDist = math.huge
			for cpIdx, cp in checkpoints do
				local dist = (p1 - cp.Position).Magnitude
				if dist < bestDist then
					bestDist = dist
					checkpointIndex = cpIdx
				end
			end

			for seg = 0, SEGMENTS_PER_SPAN - 1 do
				local t = seg / SEGMENTS_PER_SPAN
				local position = catmullRomSpline(p0, p1, p2, p3, t)
				local tangent = catmullRomTangent(p0, p1, p2, p3, t)
				tangent = (tangent * HORIZONTAL).Unit

				table.insert(path, {
					position = position + Vector3.new(0, 3, 0),
					tangent = tangent,
					checkpointIndex = checkpointIndex
				})
			end
		end

		return path
	end

	-- Get waypoints from traced path near a checkpoint
	local function getPathWaypointsNear(tracedPath: {{position: Vector3, tangent: Vector3, checkpointIndex: number}}, checkpointIdx: number, count: number, reverse: boolean)
		local waypoints = {}
		local n = #tracedPath
		if n == 0 then return waypoints end

		local startIdx = 1

		-- Find first sample at this checkpoint
		for i, sample in ipairs(tracedPath) do
			if sample.checkpointIndex == checkpointIdx then
				startIdx = i
				break
			end
		end

		-- Get waypoints in direction (wrap around for circular track)
		local step = reverse and -3 or 3
		for i = 0, count - 1 do
			local rawIdx = startIdx + (i * step)
			-- Wrap around the circular path
			local idx = ((rawIdx - 1) % n) + 1
			local sample = tracedPath[idx]
			local tangent = reverse and -sample.tangent or sample.tangent
			table.insert(waypoints, {position = sample.position, tangent = tangent})
		end

		return waypoints
	end

	local CarSpawning = ServerScriptService:FindFirstChild("CarSpawning")
	local spawnCar = require(CarSpawning.spawnCar)
	local destroyPlayerCars = require(CarSpawning.destroyPlayerCars)
	local getOwnerTag = require(CarSpawning.getOwnerTag)
	local getCheckpoints = require(ReplicatedStorage.Utility.getCheckpoints)

	local kiosks = CollectionService:GetTagged("CarSpawnKiosk")
	local spawnLocation = kiosks[1]:FindFirstChild("SpawnLocation")

	destroyPlayerCars(player)
	spawnCar(spawnLocation.CFrame, player)
	task.wait(2)

	local character = player.Character
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	local ownerTag = getOwnerTag(player)
	local playerCar = nil
	for _, obj in Workspace:GetChildren() do
		if obj:IsA("Model") and obj:HasTag(ownerTag) then
			playerCar = obj
			break
		end
	end

	local seat = playerCar:FindFirstChildWhichIsA("VehicleSeat", true)
	character:PivotTo(seat.CFrame * CFrame.new(0, 2, 0))
	task.wait(0.1)
	seat:Sit(humanoid)
	task.wait(0.5)

	for _, part in playerCar:GetDescendants() do
		if part:IsA("BasePart") then
			pcall(function() part:SetNetworkOwner(player) end)
		end
	end

	local raceContainers = CollectionService:GetTagged("Race")
	local raceContainer = raceContainers[1]

	local startingArea = raceContainer:FindFirstChild("StartingArea")

	local checkpointsFolder = raceContainer:FindFirstChild("Checkpoints")
	local checkpoint1 = checkpointsFolder:FindFirstChild("Checkpoint1")

	local carPosition = startingArea.CFrame.Position + Vector3.new(0, 3, 0)
	local lookDir = (checkpoint1.Position - carPosition) * Vector3.new(1, 0, 1)
	local carCFrame = CFrame.lookAt(carPosition, carPosition + lookDir.Unit)

	-- Set short race start times before entering starting area
	raceContainer:SetAttribute("startDelay", 2)
	raceContainer:SetAttribute("startCountdown", 2)

	-- Trace road path for all tests
	local checkpoints = getCheckpoints(raceContainer)
	local tracedPath = traceRoadPath(checkpoints, 5)

	-- Wait for client ready
	if not clientReady then clientReadyEvent.Event:Wait() end

	-- Test 1: No warning when not in race
	local wrongCFrame = carCFrame * CFrame.Angles(0, math.pi, 0)
	playerCar:PivotTo(wrongCFrame)
	task.wait(0.5)
	local test1Waypoints = getPathWaypointsNear(tracedPath, 1, 15, true)
	testRemote:FireClient(player, "DRIVE_ALONG_TRACK", {
		waypoints = test1Waypoints,
		duration = 3
	})
	waitForResult()
	task.wait(1.5)
	testRemote:FireClient(player, "CHECK_WARNING", false)
	local passed = waitForResult()
	logTest(1, "no warning when not in race", passed)
	assert(passed, "No warning when not in race")
	testRemote:FireClient(player, "STOP_DRIVING")
	waitForResult()

	playerCar:PivotTo(carCFrame)
	task.wait(2)

	local startTime = os.clock()
	while os.clock() - startTime < 15 do
		if CollectionService:HasTag(player, "InRace") then break end
		task.wait(0.5)
	end
	-- sanity check
	assert(CollectionService:HasTag(player, "InRace"), "Player should be in race")

	startTime = os.clock()
	while os.clock() - startTime < 20 do
		if raceContainer:GetAttribute("managerState") == "Racing" then break end
		task.wait(0.5)
	end
	-- sanity check
	assert(raceContainer:GetAttribute("managerState") == "Racing", "Race should have started")

	local countdown = raceContainer:GetAttribute("startCountdown") or 3
	task.wait(countdown + 2)

	local function runTests()
		local testNum = 2

		-- Helper: drive along track using waypoints, check warning, assert, stop
		local function driveAndCheck(cframe, checkpointIdx, reverse, expectVisible, testName, duration)
			duration = duration or 3
			local waypoints = getPathWaypointsNear(tracedPath, checkpointIdx, 15, reverse)

			if cframe then
				playerCar:PivotTo(cframe)
				task.wait(0.5)
			end
			testRemote:FireClient(player, "DRIVE_ALONG_TRACK", {
				waypoints = waypoints,
				duration = duration
			})
			waitForResult()
			task.wait(1.5)
			testRemote:FireClient(player, "CHECK_WARNING", expectVisible)
			local passed = waitForResult()
			logTest(testNum, testName, passed)
			assert(passed, testName)
			testNum = testNum + 1
			testRemote:FireClient(player, "STOP_DRIVING")
			waitForResult()
		end

		-- Test 2: No warning when stationary
		testRemote:FireClient(player, "CHECK_WARNING", false)
		local passed = waitForResult()
		logTest(testNum, "no warning when stationary", passed)
		assert(passed, "no warning when stationary")
		testNum = testNum + 1

		local correctCFrame = playerCar:GetPivot()
		local wrongCFrame = correctCFrame * CFrame.Angles(0, math.pi, 0)

		-- Test 3: Warning visible when moving in the wrong direction
		driveAndCheck(wrongCFrame, 1, true, true, "warning visible when facing/moving wrong direction")

		-- Test 4: No warning when reversing in the correct direction (special case - uses DRIVE_REVERSE)
		playerCar:PivotTo(wrongCFrame)
		task.wait(0.5)
		testRemote:FireClient(player, "DRIVE_REVERSE")
		waitForResult()
		task.wait(1.5)
		testRemote:FireClient(player, "CHECK_WARNING", false)
		local test4Passed = waitForResult()
		logTest(testNum, "no warning when facing wrong but moving correct", test4Passed)
		assert(test4Passed, "no warning when facing wrong but moving correct")
		testNum = testNum + 1
		testRemote:FireClient(player, "STOP_DRIVING")
		waitForResult()

		-- Test 5: No warning when moving in the correct direction
		driveAndCheck(correctCFrame, 1, false, false, "no warning when facing/moving correct direction")

		-- Get checkpoint indices for early/mid/late positions
		local n = #checkpoints
		local testIndices = {math.ceil(n * 0.25), math.ceil(n * 0.5), math.ceil(n * 0.75)}

		-- Tests 6-11: Checkpoint direction tests at early/mid/late positions
		local positionLabels = {"early", "mid", "late"}
		for i, idx in ipairs(testIndices) do
			local checkpoint = checkpoints[idx]
			if not checkpoint then continue end

			local posLabel = positionLabels[i] or "checkpoint"
			local cpPosition = checkpoint.Position + Vector3.new(0, 8, 0) -- Higher to avoid ground collision
			local trackDir = (checkpoint.CFrame.LookVector * HORIZONTAL).Unit
			local cpCorrectCFrame = CFrame.lookAt(cpPosition, cpPosition + trackDir)
			local cpWrongCFrame = cpCorrectCFrame * CFrame.Angles(0, math.pi, 0)

			-- Drive along track in correct direction
			driveAndCheck(cpCorrectCFrame, idx, false, false, posLabel .. " checkpoint - correct direction", 8)
			-- Drive along track in wrong direction (car faces backwards, moves backwards along track)
			driveAndCheck(cpWrongCFrame, idx, true, true, posLabel .. " checkpoint - wrong direction", 8)
		end

		-- Test 12: Full lap wrong direction at high speed - verify warning stays visible
		local allWaypoints = {}
		for i = 1, #tracedPath do
			local sample = tracedPath[i]
			table.insert(allWaypoints, {
				position = sample.position,
				tangent = -sample.tangent -- Reversed for wrong direction
			})
		end

		-- Start at checkpoint 1, facing wrong direction
		local startCheckpoint = checkpoints[1]
		local startPos = startCheckpoint.Position + Vector3.new(0, 8, 0)
		local startDir = -(startCheckpoint.CFrame.LookVector * HORIZONTAL).Unit
		local startCFrame = CFrame.lookAt(startPos, startPos + startDir)

		playerCar:PivotTo(startCFrame)
		task.wait(0.5)

		-- Calculate approximate lap distance and time needed
		local totalDistance = 0
		for i = 1, #allWaypoints - 1 do
			local p1 = allWaypoints[i].position
			local p2 = allWaypoints[i + 1].position
			totalDistance = totalDistance + (p2 - p1).Magnitude
		end
		-- Add distance from last to first (loop closure)
		totalDistance = totalDistance + (allWaypoints[1].position - allWaypoints[#allWaypoints].position).Magnitude

		local speed = 100
		local lapTime = math.ceil(totalDistance / speed) + 5 -- Add buffer time

		-- Drive full lap at high speed, check warning multiple times
		testRemote:FireClient(player, "DRIVE_ALONG_TRACK", {
			waypoints = allWaypoints,
			duration = lapTime,
			speed = speed,
			turnSpeed = 20 -- Fast turning for high speed
		})
		waitForResult()

		-- Check warning visibility during the lap (every ~20% of lap)
		local checkInterval = math.max(2, math.floor(lapTime / 6))
		local warningChecks = 0
		local warningVisible = 0
		for checkNum = 1, 5 do
			task.wait(checkInterval)
			testRemote:FireClient(player, "CHECK_WARNING", true)
			local checkPassed = waitForResult()
			warningChecks = warningChecks + 1
			if checkPassed then warningVisible = warningVisible + 1 end

			-- Check if car is near start (completed lap)
			local carPos = playerCar:GetPivot().Position
			local distFromStart = ((carPos - startPos) * HORIZONTAL).Magnitude
			if checkNum >= 3 and distFromStart < 50 then
				break
			end
		end

		testRemote:FireClient(player, "STOP_DRIVING")
		waitForResult()

		local fullLapPassed = warningVisible >= math.max(1, warningChecks - 1) -- Allow 1 miss
		logTest(testNum, string.format("full lap wrong direction (%d/%d checks passed)", warningVisible, warningChecks), fullLapPassed)
		assert(fullLapPassed, "full lap wrong direction")
	end

	local success, err = pcall(runTests)
	if not success then
		warn("Test error: " .. tostring(err))
	end

	testRemote:FireClient(player, "TESTS_COMPLETE")
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(_logService)
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local RunService = game:GetService("RunService")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local testRemote = ReplicatedStorage:WaitForChild(testRemoteName, 5) :: RemoteEvent

	local driveConnection = nil

	-- Search PlayerGui for "WRONG DIRECTION" text
	local function findWarningElement()
		for _, desc in playerGui:GetDescendants() do
			if desc:IsA("GuiObject") then
				local ok, text = pcall(function() return desc.Text end)
				if ok and text then
					local upper = string.upper(text)
					if string.find(upper, "WRONG") and string.find(upper, "DIRECTION") then
						return desc
					end
				end
			end
		end
		return nil
	end

	-- Check element and ancestors are visible
	local function isWarningVisible(element)
		if not element or not element.Parent then return false end
		local current = element
		while current and current ~= playerGui do
			if current:IsA("GuiObject") and current.Visible == false then return false end
			current = current.Parent
		end
		return element.Visible == true
	end

	local function getSeatAndCar()
		local character = player.Character
		if not character then return nil, nil end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid or not humanoid.SeatPart or not humanoid.SeatPart:IsA("VehicleSeat") then
			return nil, nil
		end
		local seat = humanoid.SeatPart
		local car = seat:FindFirstAncestorWhichIsA("Model")
		if not car or not car.PrimaryPart then return nil, nil end
		return seat, car
	end

	local HORIZONTAL = Vector3.new(1, 0, 1)

	-- Helper: find nearest waypoint and return its tangent
	local function findNearestWaypointTangent(car: Model, waypoints: {{position: Vector3, tangent: Vector3}}): Vector3
		local carPos = car:GetPivot().Position * HORIZONTAL
		local nearestIdx = 1
		local nearestDist = math.huge
		for i, wp in ipairs(waypoints) do
			local wpPos = wp.position :: Vector3
			local dist = ((wpPos * HORIZONTAL) - carPos).Magnitude
			if dist < nearestDist then
				nearestDist = dist
				nearestIdx = i
			end
		end
		return waypoints[nearestIdx].tangent :: Vector3
	end

	-- Helper: steer car to face a direction
	local function steerTowardDirection(car: Model, direction: Vector3, turnSpeed: number, dt: number)
		local currentCFrame = car:GetPivot()
		local targetCFrame = CFrame.lookAt(currentCFrame.Position, currentCFrame.Position + direction)
		local newCFrame = currentCFrame:Lerp(targetCFrame, math.min(1, turnSpeed * dt))
		car:PivotTo(newCFrame)
	end

	local function handleCommand(command, data)
		if command == "CHECK_WARNING" then
			local expectVisible = data
			local element = findWarningElement()
			if not element then
				-- No element: pass if expecting hidden, fail if expecting visible
				testRemote:FireServer("CHECK_DONE", not expectVisible)
				return not expectVisible
			end
			local visible = isWarningVisible(element)
			local passed = (visible == expectVisible)
			testRemote:FireServer("CHECK_DONE", passed)
			return passed

		elseif command == "DRIVE_REVERSE" then
			local seat, car = getSeatAndCar()
			if not seat or not car then
				testRemote:FireServer("CHECK_DONE", false)
				return false
			end

			if driveConnection then driveConnection:Disconnect() end
			driveConnection = RunService.Heartbeat:Connect(function()
				car.PrimaryPart.AssemblyLinearVelocity = -seat.CFrame.LookVector * 25
			end)
			testRemote:FireServer("CHECK_DONE", true)
			return true

		elseif command == "DRIVE_ALONG_TRACK" then
			local waypoints = data.waypoints
			local duration = data.duration or 3
			local speed = data.speed or 30
			local turnSpeed = data.turnSpeed or 8

			if driveConnection then driveConnection:Disconnect() end
			local _, car = getSeatAndCar()
			if not car then
				testRemote:FireServer("CHECK_DONE", false)
				return false
			end

			local startTime = os.clock()

			driveConnection = RunService.Heartbeat:Connect(function(dt)
				if os.clock() - startTime >= duration then
					return
				end

				local tangent = findNearestWaypointTangent(car, waypoints)
				steerTowardDirection(car, tangent, turnSpeed, dt)
				car.PrimaryPart.AssemblyLinearVelocity = tangent * speed
			end)

			testRemote:FireServer("CHECK_DONE", true)
			return true

		elseif command == "STOP_DRIVING" then
			if driveConnection then
				driveConnection:Disconnect()
				driveConnection = nil
			end
			local seat, car = getSeatAndCar()
			if seat then
				seat.ThrottleFloat = 0
				seat.SteerFloat = 0
			end
			if car and car.PrimaryPart then car.PrimaryPart.AssemblyLinearVelocity = Vector3.zero end
			testRemote:FireServer("CHECK_DONE", true)
			return true

		elseif command == "TESTS_COMPLETE" then
			return true
		end
		return false
	end

	testRemote:FireServer("CLIENT_READY")

	while true do
		local command, data = testRemote.OnClientEvent:Wait()
		handleCommand(command, data)
		if command == "TESTS_COMPLETE" then break end
	end
end)

return eval
