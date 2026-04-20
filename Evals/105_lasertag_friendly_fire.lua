--!strict

---------------------------------------------------------------------
-- OPENEVAL / ENGINE STABILITY HELPERS
---------------------------------------------------------------------
local function valid(player, query, timeout)
	-- Helper to safely retrieve a player's character or sub-instance in OpenEval,
	-- accounting for unstable character lifecycles and respawns.
	-- Retries once per second until found or timeout is exceeded.
	if timeout == nil then
		timeout = 10
	end

	local instance = player.Character

	if instance and query then
		instance = instance:QueryDescendants(query)[1]
	end

	if instance and instance:IsDescendantOf(workspace) then
		return instance
	end

	timeout = timeout - 1
	-- CHECK [01 Global Sanity]: Valid Characters & Subinstances
	assert(timeout > 0, "[01 Global Sanity]: Timed out waiting for valid " .. (query or "Character"))
	task.wait(1)
	
	return valid(player, query, timeout)
end

local function ServerScriptLoader(module)
	-- Helper object to validate and recover server scripts that
	-- would trigger the Server Require Error, making use of an
	-- empty existing ModuleScript to collect them for later
	-- server execution within the serverCheck function

	-- Validate that the recovery module exists, is a ModuleScript,
	-- and is empty so we can safely overwrite it.

	local self = {}
	module = module or game:FindFirstChild("LoadedCode")

	function self:tag()
		if not module or not module:IsA("ModuleScript") or not module.Source:match("^%s*return%s+nil%s*$") then
			return false
		end
		for index, script in game:QueryDescendants("Script") do
			if script.RunContext == Enum.RunContext.Server and string.find(script.Source, "require") then
				script:AddTag("ServerScriptInjectionRequired")
				script.Source ..= "\n\nscript:RemoveTag('ServerScriptInjectionRequired')"
			end
		end
		return true
	end

	function self:load()
		local instances = game:QueryDescendants(".ServerScriptInjectionRequired")
		if not #instances then
			return false
		end

		local code = "local scripts = {}\n\n"
		for index, instance in instances do
			code ..= `scripts[{index}] = function(script)\n{instance.Source}\nend\n\n`
		end
		code ..= "return scripts"

		module.Source = code
		local scripts = require(module)
		for index, instance in instances do
			scripts[index](instance)
		end
		return true
	end

	return self
end

-- Use the empty `LoadedCode` ModuleScript for server script recovery
local serverScripts = ServerScriptLoader()

local function loadDependencies(requested)
	-- Robust dependency loader for the purpose of loading in modules that
	-- may be misplaced in studio execution

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
	for moduleName, module in modules do
		modules[moduleName] = require(module)
	end

	return modules
end
-- Load all LoadedCode dependencies
local dependencies = loadDependencies()
local types = dependencies.types
local utils_he = dependencies.utils_he
local utils_runs = dependencies.utils_runs
local utils_checks = dependencies.utils_checks
local lib = dependencies.lib

local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
	scenario_name = "pilot_027",
	prompt = {
		{
			{
				role = "user",
				content = [[Allow players to hit members of their own team / Allow friendly fire in this game.]],
				request_id = "pilot_027"
			}
		}
	},
	place = "laser_tag.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	}
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
end

---------------------------------------------------------------------
-- REFERENCE SOLUTION
---------------------------------------------------------------------
eval.reference = function()
	-- Remove team collision filtering
	game:GetService("ServerScriptService").Gameplay.Scripts.TeamCollisionFiltering:Destroy()

	-- Modify canPlayerDamageHumanoid to ignore team
	game:GetService("ReplicatedStorage").Blaster.Utility.canPlayerDamageHumanoid.Source = [[local Players = game:GetService("Players")

local function canPlayerDamageHumanoid(player: Player, taggedHumanoid: Humanoid): boolean
	-- As long as the humanoid is alive, apply damage
    return taggedHumanoid.Health > 0
end

return canPlayerDamageHumanoid]]
end

---------------------------------------------------------------------
-- CHECK SCENE – Used To Setup The Environment For RunTime Tests
---------------------------------------------------------------------
eval.check_scene = function()
	serverScripts:tag()
	-- Disable AutoAssignable on all teams, aside from the first
	local teams = game:GetService("Teams"):GetTeams()

	-- CHECK [02 Scene Sanity]: Team Exists
	assert(#teams > 0, "[02 Scene Sanity]: No teams found")

	for _, team in teams do
		team.AutoAssignable = false
	end

	teams[1].AutoAssignable = true

	-- Create a RemoteEvent for unit testing, as it's better to have it prior to runTime
	local testRemote = Instance.new("RemoteEvent")
	testRemote.Name = "UnitTestRemote"
	testRemote.Parent = game:GetService("ReplicatedStorage")
end

-- eval.check_game = function()
-- end

---------------------------------------------------------------------
-- SERVER CHECK – Core Tests
---------------------------------------------------------------------
assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	-- OPENEVAL WORKAROUND: Ensure server scripts loaded properly
	serverScripts:load()

	-- Grab the test remote and create it if it doesn't exist immediately, so-as to allow the clientCheck to proceed
	local testRemote = game:GetService("ReplicatedStorage"):WaitForChild("UnitTestRemote", 10)
	if not testRemote then
		testRemote = Instance.new("RemoteEvent")
		testRemote.Name = "UnitTestRemote"
		testRemote.Parent = game:GetService("ReplicatedStorage")
	end

	local Players = game:GetService("Players")
	local startTime = os.clock()
	local currentPlayers

	repeat
		-- CHECK [03 Server Sanity]: Two Players Arrive
		assert(os.clock() < startTime + 20, "[03 Server Sanity]: Timed out waiting for players")
		currentPlayers = Players:GetPlayers()
		task.wait(1)
	until #currentPlayers >= 2	


	-- Make Player humanoids immortal so that testing can proceed through multiple weapon fires without worry
	for _, player in currentPlayers do
		local humanoid = valid(player, "Humanoid")
		local enforcedStates = {}

		for _, name in {"Dead", "FallingDown", "Ragdoll", "Physics"} do
			local state = Enum.HumanoidStateType[name]
			enforcedStates[state] = true
			humanoid:SetStateEnabled(state, false)
		end

		humanoid.BreakJointsOnDeath = false

		-- Future insurance: re-disable enforced states if re-enabled
		humanoid.StateEnabledChanged:Connect(function(state, enabled)
			if enabled and enforcedStates[state] then
				humanoid:SetStateEnabled(state, false)
				humanoid.BreakJointsOnDeath = false
			end
		end)
	end

	task.wait(3)

	local shooter = currentPlayers[1]
	local target = currentPlayers[2]

	if shooter.Team ~= target.Team then
		-- Teams should match due to checkScene code; catch if something strange happens
		warn("Teams unexpectedly differ at spawn; fixing this and proceeding (but could indicate unexpected behavior)")
		target.Team = shooter.Team
	end

	local shooterCharacter = valid(shooter)
	local targetCharacter = valid(target)

	-- Default to shooterRoot if no spawn location as fallback in case no spawn location is later found
	local location = shooterCharacter:GetPivot()
	
	-- Attempt to grab shooter's team's spawn location; default to any spawn location
	for _, s in workspace:QueryDescendants("SpawnLocation") do
		location  = s:GetPivot()
		if s.TeamColor == shooter.TeamColor then
			break
		end
	end

	-- Move shooter to dead-center of spawn location, to ensure there is room in front of them
	shooterCharacter:PivotTo(location)

	-- Move target to exactly 2 studs in front of shooter on all axes
	targetCharacter:PivotTo(location * CFrame.new(0, 0, -2))

	local weaponCount = 0
	local damageCount = 0
	local backpack = shooter:WaitForChild("Backpack", 10)

	-- Test every blaster in the backpack, increasing damageCount for those that deal damage to the target
	for _, tool in backpack:GetChildren() do
		
		if tool:IsA("Tool") and tool:FindFirstChild("Blaster") then
			weaponCount += 1
			local humanoid = valid(target, "Humanoid")
			local initialHealth = humanoid.Health
			testRemote:FireClient(shooter, tool)
			task.wait(3)
			if humanoid.Health < initialHealth then
				damageCount += 1
			end
			humanoid.Health = initialHealth
		end
	end

	-- CHECK [04 Server Sanity]: Blasters Exist
	assert(weaponCount > 0, "[04 Server Sanity]: No blasters found in shooter's backpack")
	-- CHECK [05 Server Correctness]: Damage Dealt By One Weapon
	assert(damageCount > 0, "[05 Server Correctness]: No weapon dealt damage to friendly target")
	-- CHECK [06 Server Correctness]: Damage Dealt By All Weapons
	assert(damageCount == weaponCount, "[06 Server Correctness]: Not all weapons dealt damage to friendly target")
end

---------------------------------------------------------------------
-- CLIENT CHECKS – Fires Weapons Client-Side Upon Server Requests
---------------------------------------------------------------------
assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
local sharedClientCheck = function()
	local Players = game:GetService("Players")
	local player = Players.LocalPlayer

	local testRemote = game:GetService("ReplicatedStorage"):WaitForChild("UnitTestRemote", 30)

	testRemote.OnClientEvent:Connect(function(tool)
        -- OPENEVAL WORKAROUND: Ensure the camera is properly placed, as open-eval sometimes misplaces it on the client in FPS modes
		workspace.CurrentCamera:PivotTo(valid(player):GetPivot())

		valid(Players.LocalPlayer, "Humanoid"):EquipTool(tool)

		task.wait(1)
		tool:Activate()
		task.wait(1.5)

		tool:Deactivate()
	end)
end
table.insert(eval.runConfig.clientChecks, sharedClientCheck)
table.insert(eval.runConfig.clientChecks, sharedClientCheck)

return eval