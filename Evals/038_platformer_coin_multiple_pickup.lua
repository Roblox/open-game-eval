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
    scenario_name = "038_platformer_coin_multiple_pickup",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make it so that the coins can be picked up multiple times.]],
                        
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
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")
    
    local coinController = ReplicatedStorage:FindFirstChild("CoinController", true)
    
    if coinController and coinController:IsA("ModuleScript") then
        coinController.Source = [=[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Gameplay = ReplicatedStorage:WaitForChild("Gameplay")
local Constants = require(Gameplay.Constants)
local disconnectAndClear = require(ReplicatedStorage.Utility.disconnectAndClear)
local playSoundFromSource = require(ReplicatedStorage.Utility.playSoundFromSource)
local simpleParticleBurst = require(ReplicatedStorage.Utility.simpleParticleBurst)

local player = Players.LocalPlayer
local visualTemplate = Gameplay.Objects.Coin
local pickupSoundTemplate = Gameplay.Sounds.PickupCoin
local pickupParticlesTemplate = Gameplay.Effects.PickupParticles
local remotes = Gameplay.Remotes
local pickupCoinRemote = remotes.PickupCoin

local audioEmitterTemplate = script:FindFirstChild("CoinAudioEmitter")
if not audioEmitterTemplate then
    audioEmitterTemplate = Instance.new("Sound")
    audioEmitterTemplate.Name = "CoinAudioEmitter"
end

local pickupSoundPitch = 1
local lastPickup = 0
local pickedUpCoins = {} 

local CoinController = {}
CoinController.__index = CoinController

function CoinController.new(coin: BasePart)
	local visual = visualTemplate:Clone()
	visual:PivotTo(coin.CFrame)
	visual.Parent = Workspace

	local audioEmitter = audioEmitterTemplate:Clone()
	audioEmitter.Parent = coin

	local self = {
		coin = coin,
		visual = visual,
		audioEmitter = audioEmitter,
		connections = {},
	}
	setmetatable(self, CoinController)

	self:initialize()

	return self
end

function CoinController:initialize()
	table.insert(
		self.connections,
		self.coin.Touched:Connect(function(hit: BasePart)
			if hit.Parent == player.Character then
				self:tryPickup()
			end
		end)
	)
	self:updateVisibility()
end

function CoinController:tryPickup()
	if pickedUpCoins[self.coin] then
		return
	end

	local timeSinceLastPickup = os.clock() - lastPickup
	lastPickup = os.clock()

	if timeSinceLastPickup > Constants.COIN_PICKUP_SOUND_PITCH_RESET_TIME then
		pickupSoundPitch = 1
	else
		pickupSoundPitch += Constants.COIN_PICKUP_SOUND_PITCH_INCREASE
	end

	playSoundFromSource(pickupSoundTemplate, self.audioEmitter, pickupSoundPitch)
	simpleParticleBurst(pickupParticlesTemplate, self.coin.CFrame)

	pickedUpCoins[self.coin] = true
	self:updateVisibility() 

	local success = pickupCoinRemote:InvokeServer(self.coin)
    
    task.delay(3, function()
        if self.coin and self.coin.Parent then
            pickedUpCoins[self.coin] = nil
            self:updateVisibility() 
        end
    end)
end

function CoinController:updateVisibility()
	local isPickedUp = pickedUpCoins[self.coin]

	for _, descendant in self.visual:GetDescendants() do
		if descendant:IsA("BasePart") or descendant:IsA("Decal") then
			descendant.LocalTransparencyModifier = if isPickedUp then Constants.COIN_PICKUP_TRANSPARENCY else 0
		elseif descendant:IsA("Light") then
			descendant.Enabled = not isPickedUp
		end
	end
end

function CoinController:destroy()
	disconnectAndClear(self.connections)
	self.visual:Destroy()
	self.audioEmitter:Destroy()
end

return CoinController
]=]
    end

    local overrideScript = Instance.new("Script")
    overrideScript.Name = "InfiniteCoinPickupOverride"
    
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
        coins.Value = 0
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
            coins.Value += 1
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
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local ServerScriptService = game:GetService("ServerScriptService")

    local coinController = ReplicatedStorage:FindFirstChild("CoinController", true)
    assert(coinController, "CoinController module not found in ReplicatedStorage")
    assert(coinController:IsA("ModuleScript"), "CoinController is not a ModuleScript")

    local serverScript = ServerScriptService:FindFirstChild("InfiniteCoinPickupOverride")
    if not serverScript then
         warn("InfiniteCoinPickupOverride script not found in ServerScriptService. Reference code execution might have failed or not persisted.")
    end
end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local Players = game:GetService("Players")
	local localPlayer = Players.LocalPlayer
    
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local rootPart = character:WaitForChild("HumanoidRootPart", 10)

    local Gameplay = workspace:WaitForChild("Gameplay", 10)
    local CoinPickups = Gameplay and Gameplay:WaitForChild("CoinPickups", 10)
    local coins = CoinPickups and CoinPickups:GetChildren() or {}
    assert(#coins > 0, "No coins found in Workspace to test")
    local targetCoin = coins[1]
    
    local leaderstats = localPlayer:WaitForChild("leaderstats", 15)
    local coinStat = leaderstats and leaderstats:WaitForChild("Coins", 5)

    local function teleportAway()
        if character and character.PrimaryPart then
             character:PivotTo(CFrame.new(targetCoin.Position + Vector3.new(30, 10, 0)))
             character.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
        end
    end

    local function teleportToCoin()
        if character and character.PrimaryPart then
            character:PivotTo(CFrame.new(targetCoin.Position))
            character.PrimaryPart.AssemblyLinearVelocity = Vector3.zero
            task.wait(0.1)
            character:PivotTo(CFrame.new(targetCoin.Position) * CFrame.new(0.5, 0.5, 0))
        end
    end

    local function waitForStat(targetValue, timeout)
        local start = os.clock()
        while os.clock() - start < timeout do
            if coinStat.Value >= targetValue then
                return true
            end
            task.wait(0.1)
        end
        return false
    end

    teleportAway()
    task.wait(1) 

    local initialValue = coinStat.Value

    teleportToCoin()
    local successFirst = waitForStat(initialValue + 1, 4)
    assert(successFirst, "Failed to pickup coin the first time.")
    local valueAfterFirst = coinStat.Value

    teleportAway()
    task.wait(4) 

    teleportToCoin()
    local successSecond = waitForStat(valueAfterFirst + 1, 4)
    assert(successSecond, "Failed to pickup coin a second time.")
end)

return eval
