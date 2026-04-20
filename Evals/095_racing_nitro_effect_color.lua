--!strict

---------------------------------------------------------------------
-- ROBUST DEPENDENCY LOADER (Solves for OpenEval and Assitant Plugin)
---------------------------------------------------------------------
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
    scenario_name = "pilot_030",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make the nitro effect color the same color as the car.]],
                        request_id = "pilot_030"
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

---------------------------------------------------------------------
-- SETUP – Empty, unneceessary for this prompt
---------------------------------------------------------------------
eval.setup = function()
end

---------------------------------------------------------------------
-- REFERENCE SOLUTION
---------------------------------------------------------------------
eval.reference = function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local carTemplate = ReplicatedStorage:WaitForChild("Car")
	local carScripts = carTemplate:WaitForChild("Scripts")
	local carServerScripts = carScripts:WaitForChild("Server")


	local nitroColorScript = Instance.new("Script")
	nitroColorScript.Name = "NitroColor"
	nitroColorScript.Source = [[
local car = script:FindFirstAncestor("Car")
local colorPart: BasePart? = nil
local pointLights = {}
local particleEmitters = {}

for _, descendant in car:GetDescendants() do
    if descendant:IsA("PointLight") then
        table.insert(pointLights, descendant)
    elseif descendant:IsA("ParticleEmitter") then
        table.insert(particleEmitters, descendant)
    elseif not colorPart and descendant:IsA("BasePart") and descendant:HasTag("Recolor") then
        colorPart = descendant
    end
end

local function recolorNitro()
	local currentColor = colorPart.Color

	for _, light in pointLights do
		light.Color = currentColor
	end

	for _, emitter in particleEmitters do
		local newPoints = {}
		for _, keypoint in emitter.Color.Keypoints do
			if keypoint.Time ~= 1 then
				table.insert(newPoints, keypoint)
			end
		end
		table.insert(newPoints, ColorSequenceKeypoint.new(1, currentColor))
		emitter.Color = ColorSequence.new(newPoints)
	end
end

if colorPart then
	recolorNitro()
	colorPart:GetPropertyChangedSignal("Color"):Connect(recolorNitro)
end
]]
	nitroColorScript.Parent = carServerScripts
end

---------------------------------------------------------------------
-- CHECK SCENE – Empty, unneceessary for this prompt
---------------------------------------------------------------------
eval.check_scene = function()
end

-- eval.check_game = function()
-- end

---------------------------------------------------------------------
-- SERVER CHECK – Verifies nitro color changes with car changes
---------------------------------------------------------------------
assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	-- Waiting for stabilization
	task.wait(3)

	local Players = game:GetService("Players")
	if #Players:GetPlayers() == 0 then
		Players.PlayerAdded:Wait()
	end

	local player = Players:GetPlayers()[1]

	local ServerScriptService = game:GetService("ServerScriptService")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local function requireWithAlternative(instance, alternative)
		local status, result = pcall(function()
			return require(instance)
		end)
		if status then
			return result
		else
			warn(
				"Failed to require module: " .. tostring(instance) ..
				"\nError message: " .. tostring(result) ..
				"\nUsing manual fallback function"
			)
			return alternative
		end
	end

	local recolorModel = requireWithAlternative(
		ServerScriptService:WaitForChild("CarSpawning", 30):WaitForChild("recolorModel", 30),
		function(model: Model, color: Color3)
			for _, descendant in model:GetDescendants() do
				if descendant:IsA("BasePart") and descendant:HasTag("Recolor") then
					descendant.Color = color
				end
			end
		end
	)

	local spawnCar = requireWithAlternative(
		ServerScriptService:WaitForChild("CarSpawning", 30):WaitForChild("spawnCar", 30),
		function(location: CFrame, owner: Player?)
			local carTemplate = ReplicatedStorage:WaitForChild("Car", 30)
			-- Server Sanity 1: Car Template Integrity
			assert(carTemplate, "Server Sanity 1: Car template not found")

			local car = carTemplate:Clone()
			car:PivotTo(location)

			if owner then
				car:AddTag(string.format("Car_%d", player.UserId))
			end
			car:SetAttribute("owner", owner.UserId)
		end
	)

	local function validPivot(instance)
		return instance and instance:IsDescendantOf(workspace) and instance:GetPivot()
	end

	local spawnReference = validPivot(player.Character) or validPivot(workspace:WaitForChild("SpawnLocation", 30)) or CFrame.new(0,0,0)

	local carLocation = spawnReference + Vector3.new(-10, 5, -10)

	spawnCar(carLocation, player)

	local car = workspace:WaitForChild("Car", 30)
	-- Server Sanity 2: Car Spawning Integrity
	assert(car, "Server Sanity 2: Car not spawned")

	-- Waiting for stabilization
	task.wait(3)

	local colorPart: BasePart? = nil
	local pointLights = {}
	local particleEmitters = {}

	for _, descendant in car:GetDescendants() do
		if descendant:IsA("PointLight") then
			table.insert(pointLights, descendant)
		elseif descendant:IsA("ParticleEmitter") then
			table.insert(particleEmitters, descendant)
		elseif not colorPart and descendant:IsA("BasePart") and descendant:HasTag("Recolor") then
			colorPart = descendant
		end
	end

	local totalInstances = #pointLights + #particleEmitters

	local function testNitroColor()
		-- Server Sanity 3: 'Recolor' Tag Integrity
		assert(colorPart and colorPart:IsDescendantOf(car), "Server Sanity 3: No car model BaseParts found matching the tag 'Recolor'")

		local currentColor = colorPart.Color
		local matchingInstances = 0

		for _, light in pointLights do
			if light.Color == currentColor then
				matchingInstances += 1
			end
		end

		for _, emitter in particleEmitters do
			for _, keypoint in emitter.Color.Keypoints do
				if keypoint.Value == currentColor then
					matchingInstances += 1
					break
				end
			end
		end

		-- Server Sanity 4: Nitro FX Integrity
		assert(totalInstances > 0, "Server Sanity 4: No nitro effect instances found")
		-- Server Correctness 1: Single Nitro Color Match
		assert(matchingInstances > 0, "Server Correctness 1: No colors found in any nitro effect instance that match the current car color")
		-- Server Correctness 2: 50%+ Nitro Color Match
		assert(matchingInstances / totalInstances >= 0.5, "Server Correctness 2: Less than 50% of nitro effect instances match the car color")
	end

	-- Check nitro color matches initial car color
	testNitroColor()

	local testColors = {
		Color3.new(0, 1, 0),
		Color3.new(0, 0, 1),
		Color3.new(1, 0, 0),
	}

	for _, color in testColors do
		recolorModel(car, color)
		-- Waiting for stabilization
		task.wait(3)

		-- Sanity Check: Car color parts must continue to be updatable via recolorModel module or our manual alternative function to meet developer expectations, and to allow us to effectively test the solution
		assert(colorPart.Color == color, "Car color parts did not update as expected upon use of recolorModel")

		-- Check nitro color continues to match car color after car color modifications
		testNitroColor()
	end
end

---------------------------------------------------------------------
-- CLIENT CHECKS – Empty, unneceessary for this prompt
---------------------------------------------------------------------
assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)

end)

return eval