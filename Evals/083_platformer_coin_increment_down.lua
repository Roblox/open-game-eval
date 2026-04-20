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
    scenario_name = "083_platformer_coin_increment_down",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make the coins go down by 1 instead of up by 1 when collecting them. Don't let it go below 0.]],
                    }
                }
            },
    place = "platformer.rbxl",
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
    
    -- Create Server Script with DEBUFF Logic
	local overrideScript = Instance.new("Script")
	overrideScript.Name = "CoinDebuffOverride"

	overrideScript.Source = [=[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function ensureLeaderstats(player)
    if not player:FindFirstChild("leaderstats") then
        local leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
        
        local coins = Instance.new("IntValue")
        coins.Name = "Coins"
        -- Starting at 0 makes testing the "decrease" logic impossible without extra steps.
        coins.Value = 10 
        coins.Parent = leaderstats
    end
end

Players.PlayerAdded:Connect(ensureLeaderstats)
for _, player in ipairs(Players:GetPlayers()) do
    ensureLeaderstats(player)
end

local Gameplay = ReplicatedStorage:WaitForChild("Gameplay")
local Remotes = Gameplay:WaitForChild("Remotes")
local PickupCoin = Remotes:WaitForChild("PickupCoin")

local PICKUP_DISTANCE = 50 

local function onPickupCoin(player, coinPart)
    if not player.Character then return false end
    if not coinPart then return false end
    
    local distance = (player.Character.PrimaryPart.Position - coinPart.Position).Magnitude
    if distance > PICKUP_DISTANCE then return false end

    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            -- the coin pick up works similar to a debuff now
            -- the math.max is to ensure we don't go below 0
            coins.Value = math.max(0, coins.Value - 1)
            return true
        end
    end
    return false
end

PickupCoin.OnServerInvoke = onPickupCoin
]=]

	overrideScript.Parent = ServerScriptService
end

eval.check_scene = function()

end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer

	-- Wait for Leaderstats and Coins
	local leaderstats = localPlayer:WaitForChild("leaderstats", 15)
	local coinStat = leaderstats and leaderstats:WaitForChild("Coins", 5)
	assert(coinStat, "Coins stat not found in leaderstats")

	-- Wait for Character
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)

	-- Find Coins
	local Gameplay = workspace:WaitForChild("Gameplay", 10)
	local CoinPickups = Gameplay and Gameplay:WaitForChild("CoinPickups", 10)
	local coins = CoinPickups and CoinPickups:GetChildren() or {}
	assert(#coins >= 2, "Need at least 2 coins in Workspace to test scenarios")
	local coin1 = coins[1]
	local coin2 = coins[2]

	-- Helper: Robust Teleport to Ensure Physics Touch
	local function teleportAndTouch(targetPos)
		if character and character.PrimaryPart then
			-- Teleport slightly above and force velocity down
			character:PivotTo(CFrame.new(targetPos + Vector3.new(0, 3, 0)))
			character.PrimaryPart.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
			task.wait(0.2)

			-- Teleport directly INSIDE the coin
			character:PivotTo(CFrame.new(targetPos))
			character.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
			task.wait(0.2)

			-- Jiggle slightly to wake physics
			character:PivotTo(CFrame.new(targetPos + Vector3.new(0.5, 0, 0.5)))
			task.wait(0.2)
		end
	end

	local function teleportAway(targetPos)
		if character and character.PrimaryPart then
			character:PivotTo(CFrame.new(targetPos + Vector3.new(30, 20, 0)))
			character.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
		end
	end

	-- Helper: Wait for exact value match
	local function waitForChange(target, timeout)
		local s = os.clock()
		while os.clock() - s < timeout do
			if coinStat.Value == target then return true end
			task.wait(0.1)
		end
		return false
	end

	-- TEST START
	-- I realized lately, but nevertheless did that to test what we are starting with in terms of coin is wrong
	-- and so is wrong testing if the value reached 0 or not.
	-- Only sensible test here is simply picking a coin and seeing if it goes -1, or stays 0. 
	-- That's it.


	task.wait(1)


	local startValue = coinStat.Value
	print("Test started with" .. tostring(startValue) .. " coins.")

	teleportAway(coin1.Position)
	task.wait(0.5)
	teleportAndTouch(coin1.Position)

	waitForChange(startValue, 3)

	local valueAfterFirst = coinStat.Value

	-- if the starting value was greater than 0 then check if decrease happened
	if startValue > 0 then 
		assert(valueAfterFirst < startValue, "Coins were expected to decrease from the original value. Started at:" .. startValue .. ", current value:" .. valueAfterFirst)

		-- ensure that coin decreased exactly by 1
		assert(valueAfterFirst == startValue - 1, "Coin didn't go down by exact 1")
	elseif startValue == 0 then
		assert(valueAfterFirst == 0, "Coin value should stay at 0 but got: " .. valueAfterFirst)
	else
		assert(false, "Starting coin value can't be less than 0")
	end


	teleportAway(coin2.Position)
	task.wait(0.5)
	teleportAndTouch(coin2.Position)

	waitForChange(valueAfterFirst, 3)
	local valueAfterSecond = coinStat.Value

	if valueAfterFirst > 0 then
		assert(valueAfterSecond == valueAfterFirst - 1, "Second coin pickup did not decrease value correctly.")
	else
		assert(valueAfterSecond == 0, "Coin value should stay at 0 but got: " .. valueAfterSecond)
	end

end)

return eval
