--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
local types, utils_runs, utils_he, lib
if LoadedCode:FindFirstChild("EvalUtils") then
	types = require(LoadedCode.EvalUtils.types)
	utils_runs = require(LoadedCode.EvalUtils.utils_runs)
	utils_he = require(LoadedCode.EvalUtils.utils_he)
	lib = require(LoadedCode.EvalUtils.lib)
else
	types = require(game.LoadedCode.types)
end
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
	scenario_name = "121_monster_chase_at_night",
	prompt = {
		{
			{
				role = "user",
				content = [[Make 'scary monsters' spawn at night, they will chase the player]],
				
			}
		}
	},
	place = "baseplate.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	}
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local OldState = game:GetService("Workspace"):GetDescendants()

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
	local Workspace = game:GetService("Workspace")

	-- Initialize NPC that we later clone to spawn multiple instances.
	local scaryMonster = Instance.new("Model")
	scaryMonster.Parent = Workspace
	scaryMonster.Name = "ScaryMonster"

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = scaryMonster

	local part = Instance.new("Part")
	part.Parent = scaryMonster
	part.Name = "HumanoidRootPart"
	part.Color = Color3.new(0, 255, 0)
	part.Transparency = 1

	local script = Instance.new("Script")
	script.Enabled = false
	script.Parent = scaryMonster
	script.Source = [[
local NPC = script.Parent

function getClosestPlayer()
	local closest_player, closest_distance = nil, 200
	for i, player in pairs(game:GetService("Players"):GetPlayers()) do
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid", 5)

		if humanoid and player ~= NPC and NPC:FindFirstChild("HumanoidRootPart") then
			local distance = (NPC.HumanoidRootPart.Position - humanoid.RootPart.Position).Magnitude
			if distance < closest_distance then
				closest_player = player
				closest_distance = distance
			end
		end
	end
	return closest_player, closest_distance
end

while true do
	local player, distance = getClosestPlayer()
	if player and distance > 0 then
		local PathfindingService = game:GetService("PathfindingService")
		local agent = NPC.HumanoidRootPart
		
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid", 5)
		local targetPos = humanoid.RootPart.Position

		local path = PathfindingService:CreatePath()
		path:ComputeAsync(agent.Position, targetPos)
		
		for _, waypoint in ipairs(path:GetWaypoints()) do
			NPC.Humanoid:MoveTo(waypoint.Position)
			task.wait(0.2)
		end
	else
		wait(1)
	end
end
]]

	local serverScript = Instance.new("Script")
	serverScript.Parent = game:GetService("ServerScriptService")
	serverScript.Enabled = true
	serverScript.Source = [[
local scaryMonster = game:GetService("Workspace"):FindFirstChild("ScaryMonster")

local function getRandomPositionInPart(Part: BasePart): Vector3
	local cframe = Part.CFrame
	cframe *= CFrame.new(
		300 * (math.random() - 0.5),
		1,
		300 * (math.random() - 0.5)
	)

	return cframe.Position
end

local hasSpawnedMonsters = false

game:GetService("Lighting"):GetPropertyChangedSignal("ClockTime"):Connect(function()
	if hasSpawnedMonsters then
		return
	end
	-- I define night as when the sun is below the horizon.
	if game:GetService("Lighting"):GetSunDirection().Y < 0 then
		hasSpawnedMonsters = true
		
		for i = 1,2,1 do
			local clone = scaryMonster:Clone()
			clone.Name = "ScaryMonster" .. i
			clone.Parent = game.Workspace
			local rootPart = clone:FindFirstChild("HumanoidRootPart")
			rootPart.Transparency = 0
			rootPart.Position = getRandomPositionInPart(game:GetService("Workspace").Baseplate)
			local script = clone:FindFirstChild("Script")
			script.Enabled = true
		end
	end
end)
]]
end

eval.check_scene = function()
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	task.wait(3)
	
	local function findAllByNamePatterns(instances, patterns)
		local result = {}
		if type(patterns) ~= "table" then
			patterns = {patterns}
		end
		for _, instance in instances do
			local name = instance.Name:lower()
			for _, pattern in patterns do
				if name:find(pattern:lower(), 1, true) then
					table.insert(result, instance)
					break
				end
			end
		end
		return result
	end

	local Workspace = game:GetService("Workspace")

	game.Lighting:SetMinutesAfterMidnight(0)
	task.wait(1)

	assert(utils_he, "Unable to find utils_he.")
	local newObjects = utils_he.table_difference(OldState, Workspace:GetDescendants())

	local monsters = findAllByNamePatterns(newObjects, { "scary", "monster" })
	assert(#monsters > 0, 'Should spawn monsters at night time')
	
	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 5)

	-- Give monsters time to start pathfinding and begin moving
	task.wait(5)

	for _, monster in monsters do
		local prevDistance = (monster.HumanoidRootPart.Position - humanoid.RootPart.Position).Magnitude
		for i = 1,5,1 do
			task.wait(0.5)
			local newDistance = (monster.HumanoidRootPart.Position - humanoid.RootPart.Position).Magnitude
			assert(newDistance < prevDistance, "Expected the monster to move closer to the player")
			prevDistance = newDistance
		end
	end

	print("Success.")
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	
end)

return eval
