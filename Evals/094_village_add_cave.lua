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
	scenario_name = "094_village_add_cave",
	prompt = {
		{
			{
				role = "user",
				content = [[Add an enclosed cave to the map. The cave should have a ceiling, floor, and walls forming a room-like structure that a player can walk into. Don't do it on terrain.]],
			}
		}
	},
	place = "village.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	}
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

-- Here we snapshot existing parts
eval.setup = function()
	utils_runs.createPlayerScripts()

	-- Tag all pre-existing parts.
	for _, instance in pairs(workspace:GetDescendants()) do
		if instance:IsA("BasePart") then
			instance:SetAttribute("Eval_OriginalPart", true)
		end
	end
end

eval.reference = function()
	local caveScript = Instance.new("Script")
	caveScript.Enabled = true
	caveScript.Name = "GenerateCaveScript"
	caveScript.Parent = game:GetService('ServerScriptService')
	caveScript.Source = [[
		local Stone = Instance.new("Part")
		Stone.Size = Vector3.new(1, 1, 1)
		Stone.Anchored = true
		Stone.Material = Enum.Material.Granite
		Stone.Color = Color3.fromRGB(163, 162, 165)

		local scale = Stone.Size.X
		local origin = Vector3.new(-20, 15, -100)

		local rng = Random.new()
		local seed = rng:NextInteger(-103, 10e3)

		local CAVE_RADIUS = 35
		local CAVE_ROUNDING = rng:NextNumber() / 2
		local size = Vector3.new(CAVE_RADIUS * 2, CAVE_RADIUS, CAVE_RADIUS * 2)

		function distanceFromCenter(x, y, z, cx, cy, cz) 
			return math.sqrt((x - cx)^2 + (y - cy)^2 + (z - cz)^2)
		end

		function newNoise(seed: number, frequency: number)
			local noise = math.noise
			return function(p: Vector3): number
				return noise(
					seed + p.X * frequency,
					seed + p.Y * frequency,
					seed + p.Z * frequency
				)
			end
		end

		function thresholded(f, threshold)
			return function(...): boolean
				return f(...) >= threshold
			end
		end

		local density = newNoise(seed, 1/20)
		local isSolid = thresholded(density, 0)

		for x = 1, size.X do
			for y = 1, size.Y do
				if y % 10 == 0 then task.wait() end
				for z = 1, size.Z do
					local dfc = distanceFromCenter(x, y, z, CAVE_RADIUS, 0, CAVE_RADIUS)
					if dfc > CAVE_RADIUS + 1 + (CAVE_RADIUS * CAVE_ROUNDING) then continue end
								
					if dfc < CAVE_RADIUS or (y < 10) then
						if not isSolid(Vector3.new(x, y, z)) then continue end
					end

					local part = Stone:Clone()
					part.Name = "Cave"
					part:PivotTo(CFrame.new(origin.X - 1 + x*scale, origin.Y - 1 + y*scale, origin.Z - 1 + z*scale))
					part.Parent = game.Workspace
				end
			end
		end
	]]

end

eval.check_scene = function()
end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()

	-- open eval runs the serverCheck as soon as possible after the reference code
	-- but the cave logic, can sometimes take time to spawn or form
	-- assuming min 30fps might take 3.5 seconds and max 60 fps takes 10 seconds, I am considering a wait of 10 seconds
	task.wait(10)
	
	-- 1. Identify New Parts 
	local newParts = {}
	for _, instance in pairs(workspace:GetDescendants()) do
		if instance:IsA("BasePart") then
			
			-- We need parts which do not have the original attribute we placed
			if not instance:GetAttribute("Eval_OriginalPart") then

				-- Filter
				-- 1. Must be solid (CanCollide)
				-- 2. Must be chunky (Not thin like a leaf or stalk)
				local s = instance.Size
				local minDim = math.min(s.X, s.Y, s.Z)

				local isThin = minDim < 0.3 -- Leaves/Stalks are usually < 0.2 thick
				local isNonSolid = (not instance.CanCollide)

				if not isThin and not isNonSolid then
					table.insert(newParts, instance)
				end
			end
		end
	end
	
	-- Fallback: If strict filter removed everything, assume a weird cave was made and use everything.
	if #newParts == 0 then
		for _, instance in pairs(workspace:GetDescendants()) do
			if instance:IsA("BasePart") and not instance:GetAttribute("Eval_OriginalPart") then
				table.insert(newParts, instance)
			end
		end
	end

	assert(#newParts > 0, "No new parts were added to the map. The model failed to generate any geometry.")
	
	-- 2. Raycast Enclosure Check
	local function isPointInPocket(origin)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = newParts 

		local directions = {
			Vector3.new(0, 1, 0),  -- Up
			Vector3.new(0, -1, 0), -- Down
			Vector3.new(1, 0, 0),  -- Right
			Vector3.new(-1, 0, 0), -- Left
			Vector3.new(0, 0, 1),  -- Back
			Vector3.new(0, 0, -1), -- Front
		}

		local hits = 0
		local hasCeiling = false
		local hasFloor = false

		local RAY_LENGTH = 150 

		for i, dir in ipairs(directions) do
			local result = workspace:Raycast(origin, dir * RAY_LENGTH, raycastParams)
			if result then
				hits = hits + 1
				if i == 1 then hasCeiling = true end
				if i == 2 then hasFloor = true end
			end
		end

		-- STRICT 5-WALL CHECK
		if hasCeiling and hasFloor and hits >= 5 then
			return true
		end

		return false
	end

	-- 3. Adaptive Sampling Strategy
	local success = false
	
	-- This number is pretty important here, what it means is that
	-- despite having numerous parts in our newParts variable we are doing
	-- more than 600 tests to see if we can find a valid cave according to our 
	-- rules. So even if we find garbage items which were spawned after our setp() 
	-- was done, we are still holding a 99%+ rate of encountering the cave from that single
	-- part if it exists. 
	local attempts = 600
	local rng = Random.new()

	for i = 1, attempts do
		local randomPart = newParts[rng:NextInteger(1, #newParts)]

		-- ADAPTIVE RESOLUTION logic sits here
		local partScale = randomPart.Size.Magnitude
		local searchMin = math.max(1.5, partScale * 0.2)
		local searchMax = math.clamp(partScale * 1.5, 3, 25)

		local randomDir = Vector3.new(
			rng:NextNumber(-1, 1),
			rng:NextNumber(-1, 1),
			rng:NextNumber(-1, 1)
		).Unit

		local distance = rng:NextNumber(searchMin, searchMax)
		local testPoint = randomPart.Position + (randomDir * distance)

		local checkRadius = math.min(1, distance * 0.5)
		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = newParts
		overlapParams.FilterType = Enum.RaycastFilterType.Include

		local obstructions = workspace:GetPartBoundsInRadius(testPoint, checkRadius, overlapParams)

		if #obstructions == 0 then
			if isPointInPocket(testPoint) then
				success = true
				break
			end
		end
	end

	assert(success, "New parts were detected, but no enclosed cave pocket (Room with Ceiling, Floor, and 3+ Walls) was found. Open domes, arches, or simple tunnels do not count as caves.")
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	return true
end)

return eval