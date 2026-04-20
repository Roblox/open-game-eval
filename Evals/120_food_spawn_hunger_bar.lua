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
			print("Failed to find EvalUtils module: " .. moduleName)
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
	scenario_name = "120_food_spawn_hunger_bar",
	prompt = {
		{
			{
				role = "user",
				content = [[{"role":"user","content":"Make the items cheese burger and water bottle spawn in various places around the map. 
Include a hunger, thirst, and stamina bar; make these bars visible. 
Make it so when the player presses "Q," they perform a forward dash with a cooldown of 30 seconds. 
Make the cheese burger restore half of the hunger bar and the water bottle restore half of the thirst bar."}]],
				
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


---------------------------------------------------------------------
-- SETUP (unmodified)
---------------------------------------------------------------------
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


---------------------------------------------------------------------
-- REFERENCE IMPLEMENTATION
---------------------------------------------------------------------
eval.reference = function()

	-----------------------------------------------------------------
	-- Services
	-----------------------------------------------------------------
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local StarterPlayer = game:GetService("StarterPlayer")
	local InsertService = game:GetService("InsertService")
	local Workspace = game:GetService("Workspace")

	-----------------------------------------------------------------
	-- Configuration
	-----------------------------------------------------------------

	local ASSETS = {
		{
			name = "Burger",
			asset = "rbxassetid://119468521169314",
			stat = "CurrentHunger",
			color = Color3.fromRGB(255, 221, 87)
		},{
			name = "WaterBottle",
			asset = "rbxassetid://3377618038",
			stat = "CurrentThirst",
			color = Color3.fromRGB(80, 170, 255)
		}
	}

	-----------------------------------------------------------------
	-- Template Creation
	-----------------------------------------------------------------
	local function assetOrPlaceholder(asset)
		local ok, part = pcall(function()
			return InsertService:CreateMeshPartAsync(asset, Enum.CollisionFidelity.Default, Enum.RenderFidelity.Automatic)
		end)
		if ok and part then return part end
		local p = Instance.new("Part")
		p.Size = Vector3.new(2,2,2)
		return p
	end

	for _, a in ASSETS do
		local item = assetOrPlaceholder(a.asset)
		item.Name = a.name
		item.Color = a.color
		item:SetAttribute("stat", a.stat)

		item.Parent = ReplicatedStorage
		item.Material = Enum.Material.Neon
	end

	-----------------------------------------------------------------
	-- Remotes
	-----------------------------------------------------------------
	local remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage

	local DashFunction = Instance.new("RemoteFunction")
	DashFunction.Name = "DashForwardFunction"
	DashFunction.Parent = remotes

	-----------------------------------------------------------------
	-- Server: Character stats + decay
	-----------------------------------------------------------------
	local StatsScript = Instance.new("Script")
	StatsScript.Name = "StatScript"
	StatsScript.Parent = ServerScriptService
	StatsScript.Source = [[
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local MAX = 100
local HUNGER_DECAY_PER_SEC  = MAX / 80
local THIRST_DECAY_PER_SEC  = MAX / 40
local STAMINA_REGEN_PER_SEC = MAX / 30

local function setupCharacter(character)
	local hunger  = Instance.new("NumberValue")
	hunger.Name  = "CurrentHunger"
	hunger.Value = MAX
	hunger.Parent = character

	local thirst  = Instance.new("NumberValue")
	thirst.Name  = "CurrentThirst"
	thirst.Value = MAX
	thirst.Parent = character

	local stamina  = Instance.new("NumberValue")
	stamina.Name  = "CurrentStamina"
	stamina.Value = MAX
	stamina.Parent = character
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(setupCharacter)
end)

-- Decay / regen loop
RunService.Heartbeat:Connect(function(dt)
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if not char then continue end

		local hum = char:FindFirstChildOfClass("Humanoid")
		if not hum then continue end

		local hunger  = char:FindFirstChild("CurrentHunger")
		local thirst  = char:FindFirstChild("CurrentThirst")
		local stamina = char:FindFirstChild("CurrentStamina")

		if hunger then
			hunger.Value = math.max(hunger.Value - HUNGER_DECAY_PER_SEC * dt, 0)
		end

		if thirst then
			thirst.Value = math.max(thirst.Value - THIRST_DECAY_PER_SEC * dt, 0)
		end

		if stamina then
			stamina.Value = math.min(stamina.Value + STAMINA_REGEN_PER_SEC * dt, MAX)
		end

		if hunger and thirst and (hunger.Value <= 0 or thirst.Value <= 0) then
			hum.Health = 0
		end
	end
end)
]]

	-----------------------------------------------------------------
	-- Server: Dash
	-----------------------------------------------------------------
	local DashServer = Instance.new("Script")
	DashServer.Parent = ServerScriptService
	DashServer.Name = "DashServer"
	DashServer.Source = [[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DashFunction = ReplicatedStorage.Remotes.DashForwardFunction

local MAX = 100
local DASH_SPEED    = 100
local DASH_LIFT     = 10
local DASH_DURATION = 0.5

DashFunction.OnServerInvoke = function(player)
	local char = player.Character
	if not char then return false end

	local stamina = char:FindFirstChild("CurrentStamina")
	if not stamina or stamina.Value < MAX * 0.95 then
		return false
	end

	local root = char:FindFirstChild("HumanoidRootPart")
	if not root then return false end

	stamina.Value = 0

	local bv = Instance.new("BodyVelocity")
	bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
	bv.Velocity = root.CFrame.LookVector * DASH_SPEED + Vector3.new(0, DASH_LIFT, 0)
	bv.Parent = root

	task.delay(DASH_DURATION, function()
		bv:Destroy()
	end)

	return true
end
]]

	-----------------------------------------------------------------
	-- Server: Item spawning
	-----------------------------------------------------------------

	local Spawner = Instance.new("Script")
	Spawner.Name = "Spawner"
	Spawner.Parent = ServerScriptService
	Spawner.Source = [[
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local InsertService = game:GetService("InsertService")

local MAX  = 100
local HALF = 50
local INTERVAL = 6
local RADIUS  = 200
local HEIGHT  = 5

local function randomPosition()
	local base = Workspace:FindFirstChild("Baseplate")
	if not base then
		return Vector3.new(0, HEIGHT, 0)
	end

	return base.Position + Vector3.new(
		(math.random() - 0.5) * 2 * RADIUS,
		HEIGHT,
		(math.random() - 0.5) * 2 * RADIUS
	)
end

local function spawnItem(instance)
	local item = instance:Clone()
	item.Position = randomPosition()
	item.Parent = Workspace
	local used = false

	item.Touched:Connect(function(hit)
		if used then return end

		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end

		local char = player.Character
		if not char then return end

		local statName = item:GetAttribute("stat")
		if not statName then return end

		local stat = char:FindFirstChild(statName)
		if not stat then return end

		used = true

		stat.Value = math.min(stat.Value + HALF, MAX)

		item:Destroy()
		
	end)
end

while true do
	for _, template in {"Burger", "WaterBottle"} do
		spawnItem(ReplicatedStorage:FindFirstChild(template))
	end
	task.wait(INTERVAL)
end
]]

	-----------------------------------------------------------------
	-- Client: Dash input
	-----------------------------------------------------------------
	local DashClient = Instance.new("LocalScript")
	DashClient.Name = "DashClient"
	DashClient.Parent = StarterPlayer.StarterPlayerScripts
	DashClient.Source = [[
local UIS = game:GetService("UserInputService")
local DashFunction = game:GetService("ReplicatedStorage").Remotes.DashForwardFunction

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.Q then
		DashFunction:InvokeServer()
	end
end)
]]

	-----------------------------------------------------------------
	-- Client: Status bars
	-----------------------------------------------------------------
	local BarsClient = Instance.new("LocalScript")
	BarsClient.Parent = StarterPlayer.StarterPlayerScripts
	BarsClient.Source = [[
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local function createBar(statName, label, yScale, color)
	local gui = Instance.new("ScreenGui")
	gui.Name = statName .. "Gui"
	gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(0, 273, 0, 44)
	bg.Position = UDim2.new(0.02, 0, yScale, 0)
	bg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	bg.Parent = gui

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = color
	fill.BorderSizePixel = 0
	fill.Size = UDim2.fromScale(1, 1)
	fill.Parent = bg

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 24
	text.TextColor3 = Color3.new(1,1,1)
	text.Text = label
	text.Parent = bg

	local function bind(character)
		local stat = character:WaitForChild(statName)
		local function update()
			fill.Size = UDim2.fromScale(stat.Value / 100, 1)
			text.Text = string.format("%s: %d / 100", label, stat.Value)
		end
		stat.Changed:Connect(update)
		update()
	end

	if player.Character then
		bind(player.Character)
	end
	player.CharacterAdded:Connect(bind)
end

createBar("CurrentHunger",  "Hunger",  0.70, Color3.fromRGB(80, 200, 80))
createBar("CurrentThirst",  "Thirst",  0.80, Color3.fromRGB(80, 180, 200))
createBar("CurrentStamina", "Stamina", 0.90, Color3.fromRGB(220, 180, 80))
]]
end


---------------------------------------------------------------------
-- UNIT TESTING
---------------------------------------------------------------------

---------------------------------------------------------------------
-- SCENE CHECK (unused)
---------------------------------------------------------------------
eval.check_scene = function()
end

---------------------------------------------------------------------
-- GAME CHECK (unused)
---------------------------------------------------------------------
-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")

---------------------------------------------------------------------
-- SERVER CHECK (used not for testing, but making clients immortal)
---------------------------------------------------------------------
eval.runConfig.serverCheck = function()

	-----------------------------------------------------------------
	-- Services
	-----------------------------------------------------------------
	local Players = game:GetService("Players")

	-----------------------------------------------------------------
	-- Humanoid stabilization
	-----------------------------------------------------------------
	local function immortalize(humanoid)
		if not humanoid then return end

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

		-- Health clamp
		humanoid.HealthChanged:Connect(function(health)
			if health <= 0 then
				humanoid.Health = humanoid.MaxHealth
			end
		end)
	end

	-----------------------------------------------------------------
	-- Character / player hooks
	-----------------------------------------------------------------
	local function onCharacterAdded(character)
		local humanoid = character:WaitForChild("Humanoid", 5)
		if humanoid then
			immortalize(humanoid)
		end
	end

	local function onPlayerAdded(player)
		if player.Character then
			onCharacterAdded(player.Character)
		end
		player.CharacterAdded:Connect(onCharacterAdded)
	end

	-----------------------------------------------------------------
	-- Apply to existing and future players
	-----------------------------------------------------------------
	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)

	----------------------------------------------------------------
	-- Proximity prompt auto-activation
	----------------------------------------------------------------
	ProximityActiveCount = 0

	game:GetService("ProximityPromptService").PromptShown:Connect(function(prompt)
		ProximityActiveCount += 1
		task.wait(0.5)
		prompt:InputHoldBegin()
		task.wait(prompt.HoldDuration + 0.2)
		prompt:InputHoldEnd()
		ProximityActiveCount -= 1
	end)

	----------------------------------------------------------------
	-- Services / init
	----------------------------------------------------------------
	local function waitForCharacter(player)
		if player.Character then
			return player.Character
		end
		return player.CharacterAdded:Wait()
	end

	----------------------------------------------------------------
	-- Candidate
	----------------------------------------------------------------
	local Candidate = {}
	Candidate.__index = Candidate

	function Candidate.new(stat, instance, attribute)
		local self = setmetatable({}, Candidate)

		self.stat = stat
		self.instance = instance
		self.attribute = attribute

		self.id = instance:GetDebugId()
		if attribute then
			self.id ..= "|" .. attribute
		end

		self.running = false
		self.initValue = self:get()

		return self
	end

	function Candidate:get()
		if self.attribute then
			return self.instance:GetAttribute(self.attribute)
		end
		return self.instance.Value
	end

	function Candidate:disconnect()
		if self.running then
			self.running:Disconnect()
		end
		self.running = false
	end

	function Candidate:bindChanged(callback)
		self:disconnect()
		if self.attribute then
			self.running = self.instance:GetAttributeChangedSignal(self.attribute):Connect(callback)
		else
			self.running = self.instance.Changed:Connect(callback)
		end
	end

	function Candidate:isBound()
		if not self.running then
			return false
		end
		local inst = self.instance
		local stat = self.stat
		local char = stat.character
		local ok = inst
			and (inst:IsDescendantOf(stat.player)
				or (char and inst:IsDescendantOf(char)))
		if not ok then
		end
		return ok
	end

	----------------------------------------------------------------
	-- Stat
	----------------------------------------------------------------
	local Stat = {}
	Stat.__index = Stat

	function Stat.new(name, config)

		local self = setmetatable({}, Stat)
		self.name = name
		self.player = config.player or game:GetService("Players").LocalPlayer
		self.character = self.player.Character

		self.bar = nil
		self.candidates = {}

		self.refillFound = false
		self.depletedFound = false
		self.statFound = false

		self.startTime = os.clock()

		self.test = config.test
		self.test.stat = self

		self.player.CharacterAdded:Connect(function(char)
			self.character = char
			self:updateCandidates()
		end)

		self:updateCandidates()

		task.spawn(function()
			self:assertGUIBar()
		end)

		return self
	end

	function Stat:assertGUIBar()
		self.bar = nil
		local start = os.clock()
		for i = 1, 10 do
			for _, inst in self.player:WaitForChild("PlayerGui", 10):GetDescendants() do
				if inst.Name:lower():find(self.name, 1, true) then
					self.bar = inst
					break
				end
			end
			if self.bar then
				break
			end
			task.wait(1)
		end
		-- Stat Checks 1: GUI Spawning
		assert(self.bar, "Could not find GUI bar for " .. self.name .. " within ten seconds of spawning")
	end

	function Stat:finish()
		if self.refillPatterns then
			-- Stat Checks 2: Refill Item Spawning
			assert(self.refillFound, "No refill found for " .. self.name)
		end

		-- Stat Checks 3: Stat Depletions
		assert(self.depletedFound, "No depletion for " .. self.name)

		-- Stat Checks 4: Stat Refill Confirmed
		assert(self.statFound, "No refill success for " .. self.name)
	end

	function Stat:addCandidateIfMatching(instance, attribute)
		local id = instance:GetDebugId()
		if attribute then id ..= "|" .. attribute end
		if self.candidates[id] then return end

		local name = attribute or instance.Name
		if not name:lower():find(self.name, 1, true) then return end

		local c = Candidate.new(self, instance, attribute)
		self.candidates[id] = c
		self.test:onCandidateAdded(c)
	end

	function Stat:updateCandidates()
		task.spawn(function()
			for i = 0, 10 do
				if not self.character then return end

				local function checkAttributes(inst)
					for attr, v in inst:GetAttributes() do
						if type(v) == "number" then
							self:addCandidateIfMatching(inst, attr)
						end
					end
				end


				for _, container in {self.player, self.character} do
					checkAttributes(container)
					for _, inst in container:GetDescendants() do
						if inst:IsA("NumberValue") or inst:IsA("IntValue") then
							self:addCandidateIfMatching(inst)
						end
						checkAttributes(inst)
					end
				end

				task.wait(1)
			end
		end)
	end

	function Stat:confirmCandidate(candidate)
		if self.statFound then return end
		self.statFound = candidate

		for _, c in self.candidates do
			if c ~= candidate then
				c:disconnect()
			end
		end
	end

	----------------------------------------------------------------
	-- ItemRefillTest (Hunger / Thirst)
	----------------------------------------------------------------
	local refillRequests = {}

	local ItemRefillTest = {}
	ItemRefillTest.__index = ItemRefillTest

	function ItemRefillTest.new(config)
		return setmetatable({
			refillPatterns = config.refillPatterns,
			threshold = 0.4,
			low = 0.4,
			high = 0.6,
			stat = nil
		}, ItemRefillTest)
	end

	function ItemRefillTest:onCandidateAdded(candidate)

		candidate:bindChanged(function()
			local v = candidate:get()

			if v < candidate.initValue * self.threshold then
				self.stat.depletedFound = true
				refillRequests[candidate] = true
			end
		end)
	end

	local function findRefill(patterns)
		for _, inst in workspace:GetDescendants() do
			local n = inst.Name:lower()
			for _, p in patterns do
				if n:find(p, 1, true) then
					return inst
				end
			end
		end
	end

	function ItemRefillTest:tryRefill(candidate)

		if not candidate:isBound() then
			return false, "dead"
		end

		local refill = findRefill(self.refillPatterns)
		if not refill then
			return false, "no_refill"
		end
		local name = refill.Name

		self.stat.refillFound = true
		local char = self.stat.character
		char:PivotTo(refill:GetPivot())

		local low = candidate:get()
		local high = low

		repeat
			task.wait(0.1)
			high = math.max(high, candidate:get())
		until ProximityActiveCount == 0

		task.wait(0.3)
		high = math.max(high, candidate:get())

		-- Item Check 1: Workspace Removal

		print("R1")
		assert((not refill) or (not refill:IsDescendantOf(workspace)), "Refill " .. name .. " not removed from workspace")
		print("R2")
		local used = 0
		while (refill) and (refill:IsDescendantOf(self.stat.player.Backpack)) and type(refill.Activate) == "function" do
			print("R3")
			print("Refill is a tool!")
			refill:Activate()
				used += 1
				
			-- Item Check 2: Backpack Removal
			assert(
				used < 15,
				"Refill tool '" .. refill.Name .. "' still in Backpack after 15 activations"
			)
			task.wait(0.2)
			high = math.max(high, candidate:get())
		end
		print("R4")
		local diff = high - low

		return diff > candidate.initValue * self.low
			and diff < candidate.initValue * self.high,
		"tested"
	end

	----------------------------------------------------------------
	-- Dispatcher
	----------------------------------------------------------------
	local function refillDispatcher(stats)
		while true do
			local lowest, val = nil, math.huge

			for c in pairs(refillRequests) do
				if c.running then
					local v = c:get()
					if v < val then
						val = v
						lowest = c
					end
				else
					refillRequests[c] = nil
				end
			end

			if lowest then
				refillRequests[lowest] = nil

				local ok, why = lowest.stat.test:tryRefill(lowest)
				if ok then
					lowest.stat:confirmCandidate(lowest)
				else
					if not lowest.stat.statFound then
						lowest:disconnect()
					end
				end
			else
				task.wait(0.1)
			end

			local done = true
			for _, s in stats do
				done = done and s.statFound
			end
			if done then
				return
			end
		end
	end

	----------------------------------------------------------------
	-- CooldownRefillTest (Stamina)
	----------------------------------------------------------------
	local CooldownRefillTest = {}
	CooldownRefillTest.__index = CooldownRefillTest

	function CooldownRefillTest.new(config)
		return setmetatable({
			threshold = 0.1,
			cooldown = config.cooldownSeconds or 30,
			stat = nil
		}, CooldownRefillTest)
	end

	function CooldownRefillTest:onCandidateAdded(candidate)

		candidate:bindChanged(function()
			local v = candidate:get()

			if v < candidate.initValue * self.threshold then
				self.stat.depletedFound = true
				candidate:disconnect()

				task.spawn(function()
					task.wait(self.cooldown)

					local now = candidate:get()

					if now >= candidate.initValue * 0.9 then
						self.stat:confirmCandidate(candidate)
					end
				end)
			end
		end)
	end

	----------------------------------------------------------------
	-- Dash helper
	----------------------------------------------------------------
	local Players = game:GetService("Players")

	local function tryGetDashContext(player)
		local character = player.Character
		if not character or not character:IsDescendantOf(workspace) then
			return nil
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return nil
		end

		local root = humanoid.RootPart
		if not root then
			return nil
		end

		return {
			character = character,
			humanoid = humanoid,
			root = root,
			pivot = character:GetPivot()
		}
	end

	local function didDash(player)
		player = player or Players.LocalPlayer

		-- bounded readiness window (startup stabilization)
		local ctx
		for _ = 1, 20 do -- ~2 seconds max
			ctx = tryGetDashContext(player)
			if ctx then break end
			task.wait(0.1)
		end

		if not ctx then
			error("[DASH] Character never stabilized for dash test")
		end

		-- perform dash
		utils_runs.sendKeyEvent(true, Enum.KeyCode.Q)
		task.wait(0.05)
		utils_runs.sendKeyEvent(false, Enum.KeyCode.Q)
		task.wait(1)

		-- re-sample (no attempt to detect respawn; just re-check safely)
		local after = tryGetDashContext(player)
		if not after then
			return false
		end

		local dist = (after.pivot.Position - ctx.pivot.Position).Magnitude

		return dist > ctx.humanoid.WalkSpeed
	end


	----------------------------------------------------------------
	-- STAT CREATION
	----------------------------------------------------------------
	local vitals = {
		hunger = Stat.new("hunger", {
			test = ItemRefillTest.new({ refillPatterns = { "burger" } })
		}),
		thirst = Stat.new("thirst", {
			test = ItemRefillTest.new({ refillPatterns = { "water", "bottle" } })
		})
	}

	local stamina = Stat.new("stamina", {
		test = CooldownRefillTest.new({ cooldownSeconds = 30 })
	})

	----------------------------------------------------------------
	-- STAMINA TEST
	----------------------------------------------------------------
	-- Waiting to stabilize the Player & Character on OpenEval

	task.wait(3)

	-- Dash Check 1: Initial dash works
	assert(didDash(), "Initial dash failed")

	task.wait(10)

	-- Dash Check 2: Cooldown enforced
	assert(not didDash(), "Dash during cooldown")

	task.wait(21)

	-- Dash Check 3: Cooldown recovery
	assert(didDash(), "Dash failed after cooldown")

	stamina:finish()


	----------------------------------------------------------------
	-- HUNGER / THIRST
	----------------------------------------------------------------
	task.spawn(function()
		refillDispatcher(vitals)
	end)

	for i = 1, 300 do
		local done = true
		for _, s in vitals do
			done = done and s.statFound
		end
		if done then break end
		task.wait(1)
	end

	for name, s in vitals do
		s:finish()
	end
end)

return eval