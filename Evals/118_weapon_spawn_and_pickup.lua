--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
if LoadedCode:FindFirstChild("EvalUtils") then
	local types = require(LoadedCode.EvalUtils.types)
	local utils_runs = require(LoadedCode.EvalUtils.utils_runs)

	local lib = require(LoadedCode.EvalUtils.lib)
else
	local types = require(game.LoadedCode.types)
end

local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
	scenario_name = "118_weapon_spawn_and_pickup",
	prompt = {
		{
			{
				role = "user",
				content = [[Make the items pistol, axe, and knife spawn in various locations on the map, and ensure that the player can only pick up one of each.]],
				
			},
		},
	},
	place = "baseplate.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	},
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

	-- Create item templates in ServerStorage
	local ServerStorage = game:GetService("ServerStorage")

	local templatesFolder = ServerStorage:FindFirstChild("ItemTemplates")
	if templatesFolder then
		templatesFolder:Destroy()
	end
	templatesFolder = Instance.new("Folder")
	templatesFolder.Name = "ItemTemplates"
	templatesFolder.Parent = ServerStorage

	local function makeToolTemplate(toolName: string, color: Color3)
		local tool = Instance.new("Tool")
		tool.Name = toolName
		tool.CanBeDropped = false

		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(1, 1, 2)
		handle.Anchored = false
		handle.CanCollide = true
		handle.Color = color
		handle.Parent = tool

		tool.Parent = templatesFolder
	end

	makeToolTemplate("pistol", Color3.fromRGB(40, 40, 40))
	makeToolTemplate("axe", Color3.fromRGB(120, 60, 20))
	makeToolTemplate("knife", Color3.fromRGB(180, 180, 180))
end

eval.reference = function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local scriptName = "ItemSpawner_Pilot015"

	local existing = ServerScriptService:FindFirstChild(scriptName)
	if existing then
		existing:Destroy()
	end

	local spawnerScript = Instance.new("Script")
	spawnerScript.Name = scriptName
	spawnerScript.Source = [[
		local Players = game:GetService("Players")
		local ServerStorage = game:GetService("ServerStorage")
		local Workspace = game:GetService("Workspace")

		local templatesFolder = ServerStorage:WaitForChild("ItemTemplates")

		local RESPAWN_DELAY = 3

		local SPAWN_CONFIG = {
			{Item = "pistol", Pos = Vector3.new(10, 1, 15)},
			{Item = "pistol", Pos = Vector3.new(120, 1, 40)},
			{Item = "pistol", Pos = Vector3.new(-140, 1, -60)},

			{Item = "axe",    Pos = Vector3.new(60, 1, 180)},
			{Item = "axe",    Pos = Vector3.new(-80, 1, 140)},
			{Item = "axe",    Pos = Vector3.new(170, 1, -120)},

			{Item = "knife",  Pos = Vector3.new(-200, 1, 20)},
			{Item = "knife",  Pos = Vector3.new(30, 1, -220)},
			{Item = "knife",  Pos = Vector3.new(210, 1, 110)},
		}

		local spawnFolder = Workspace:FindFirstChild("SpawnedItems_Pilot015")
		if spawnFolder then
			spawnFolder:Destroy()
		end
		spawnFolder = Instance.new("Folder")
		spawnFolder.Name = "SpawnedItems_Pilot015"
		spawnFolder.Parent = Workspace

		local function countTools(container: Instance?, itemName: string): number
			if not container then
				return 0
			end
			local n = 0
			for _, ch in ipairs(container:GetChildren()) do
				if ch:IsA("Tool") and ch.Name == itemName then
					n += 1
				end
			end
			return n
		end

		local function playerHasItem(player: Player, itemName: string): boolean
			local backpack = player:FindFirstChild("Backpack")
			local character = player.Character

			if countTools(backpack, itemName) > 0 then
				return true
			end
			if character and countTools(character, itemName) > 0 then
				return true
			end

			return false
		end

		local function spawnPickupOnce(itemName: string, position: Vector3)
			local templateTool = templatesFolder:FindFirstChild(itemName)
			if not templateTool or not templateTool:IsA("Tool") then
				return
			end

			local handleTemplate = templateTool:FindFirstChild("Handle")
			if not handleTemplate or not handleTemplate:IsA("BasePart") then
				return
			end

			local visualModel = Instance.new("Model")
			visualModel.Name = itemName

			local visualPart = handleTemplate:Clone()
			visualPart.Name = "PickupPart"
			visualPart.CFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(math.random(0, 360)), 0)
			visualPart.Anchored = true
			visualPart.CanCollide = false
			visualPart.Parent = visualModel

			visualModel.Parent = spawnFolder

			local debounce = false
			local connection: RBXScriptConnection? = nil

			connection = visualPart.Touched:Connect(function(hit)
				if debounce then
					return
				end

				local character = hit.Parent
				local player = character and Players:GetPlayerFromCharacter(character)
				if not player then
					return
				end

				-- Ensure backpack exists
				local backpack = player:FindFirstChild("Backpack")
				if not backpack then
					backpack = player:WaitForChild("Backpack", 5)
				end
				if not backpack then
					return
				end

				-- Enforce "only pick up one of each"
				if playerHasItem(player, itemName) then
					return
				end

				debounce = true

				local realTool = templateTool:Clone()
				realTool.Parent = backpack

				if connection then
					connection:Disconnect()
					connection = nil
				end
				visualModel:Destroy()
			end)
		end

		for _, config in ipairs(SPAWN_CONFIG) do
			task.spawn(function()
				spawnPickupOnce(config.Item, config.Pos)
			end)
		end
	]]
	spawnerScript.Parent = ServerScriptService
	spawnerScript.Enabled = true
end

eval.check_scene = function() end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	local Workspace = game:GetService("Workspace")
	local ITEM_NAMES = { "pistol", "axe", "knife" }
	local MIN_DIST = 10

	local function isWorldPickupCandidate(inst: Instance, itemName: string): boolean
		if not inst:IsDescendantOf(Workspace) then
			return false
		end

		if inst:IsA("Tool") and string.lower(inst.Name):find(itemName, 1, true) then
			return true
		end

		if (inst:IsA("Model") or inst:IsA("BasePart")) and string.lower(inst.Name):find(itemName, 1, true) then
			return true
		end

		return false
	end

	local function getWorldPickupPositions(itemName: string): { Vector3 }
		local positions: { Vector3 } = {}
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if isWorldPickupCandidate(inst, itemName) then
				if inst:IsA("Tool") then
					local handle = inst:FindFirstChild("Handle")
					if handle and handle:IsA("BasePart") then
						table.insert(positions, handle.Position)
					end
				elseif inst:IsA("BasePart") then
					table.insert(positions, inst.Position)
				elseif inst:IsA("Model") then
					local pp = inst.PrimaryPart
					if pp and pp:IsA("BasePart") then
						table.insert(positions, pp.Position)
					else
						local cf, _ = inst:GetBoundingBox()
						table.insert(positions, cf.Position)
					end
				end
			end
		end
		return positions
	end

	local function hasMultipleDistinctPositions(positions: { Vector3 }): boolean
		if #positions < 2 then
			return false
		end
		for i = 1, #positions do
			for j = i + 1, #positions do
				if (positions[i] - positions[j]).Magnitude >= MIN_DIST then
					return true
				end
			end
		end
		return false
	end

	-- Unit Test: Verify items spawn in various locations (>= 2 distinct positions)
	local deadline = os.clock() + 10
	local results: { [string]: { Vector3 } } = {}

	while os.clock() < deadline do
		local allOk = true
		for _, itemName in ipairs(ITEM_NAMES) do
			local pos = getWorldPickupPositions(itemName)
			results[itemName] = pos
			if not hasMultipleDistinctPositions(pos) then
				allOk = false
			end
		end
		if allOk then
			break
		end
		task.wait(0.25)
	end

	for _, itemName in ipairs(ITEM_NAMES) do
		local pos = results[itemName] or {}
		assert(
			hasMultipleDistinctPositions(pos),
			("Expected '%s' to spawn in various locations (found %d pickup candidate(s), need >=2 distinct positions)."):format(
				itemName,
				#pos
			)
		)
	end
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local Players = game:GetService("Players")
	local Workspace = game:GetService("Workspace")

	local localPlayer = Players.LocalPlayer
	while not localPlayer do
		localPlayer = Players.LocalPlayer
		task.wait(0.1)
	end

	-- Inventory helpers
	local function getBackpack(player: Player): Instance
		local backpack = player:FindFirstChild("Backpack")
		if backpack then
			return backpack
		end
		backpack = player:WaitForChild("Backpack", 10)
		assert(backpack, "Backpack not found for player")
		return backpack
	end

	local function countToolsByName(container: Instance, toolName: string): number
		local n = 0
		for _, ch in ipairs(container:GetChildren()) do
			if ch:IsA("Tool") and ch.Name == toolName then
				n += 1
			end
		end
		return n
	end

	local function playerToolCount(player: Player, toolName: string): number
		local backpack = getBackpack(player)
		local char = player.Character
		local n = countToolsByName(backpack, toolName)
		if char then
			n += countToolsByName(char, toolName)
		end
		return n
	end

	local function waitForCharacter(player: Player): Model
		local char = player.Character
		if char then
			return char
		end
		while not char do
			char = player.Character
			task.wait(0.1)
		end
		return char
	end

	local function getHRP(char: Model): BasePart
		local hrp = char:WaitForChild("HumanoidRootPart")
		return hrp :: BasePart
	end

	local function modelToPart(m: Model): BasePart?
		if m.PrimaryPart and m.PrimaryPart:IsA("BasePart") then
			return m.PrimaryPart
		end

		local best: BasePart? = nil
		local bestVolume = -math.huge
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				local s = d.Size
				local volume = s.X * s.Y * s.Z
				if volume > bestVolume then
					bestVolume = volume
					best = d
				end
			end
		end
		return best
	end

	local function listPickupTargetsByName(itemName: string): { BasePart }
		local targets: { BasePart } = {}
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if inst:IsA("Tool") then
				local lowerName = string.lower(inst.Name)
				if lowerName == itemName or lowerName:find(itemName, 1, true) then
					local handle = inst:FindFirstChild("Handle")
					if handle and handle:IsA("BasePart") then
						table.insert(targets, handle)
					end
				end
			elseif inst:IsA("BasePart") then
				local lowerName = string.lower(inst.Name)
				if lowerName == itemName or lowerName:find(itemName, 1, true) then
					table.insert(targets, inst)
				end
			elseif inst:IsA("Model") then
				local lowerName = string.lower(inst.Name)
				if lowerName == itemName or lowerName:find(itemName, 1, true) then
					local part = modelToPart(inst)
					if part then
						table.insert(targets, part)
					end
				end
			end
		end
		return targets
	end

	local function listPickupTargetsByPromptText(itemName: string): { BasePart }
		local targets: { BasePart } = {}
		for _, inst in ipairs(Workspace:GetDescendants()) do
			if inst:IsA("ProximityPrompt") then
				local obj = string.lower(inst.ObjectText or "")
				local act = string.lower(inst.ActionText or "")
				if obj:find(itemName, 1, true) or act:find(itemName, 1, true) then
					local parent = inst.Parent
					if parent and parent:IsA("BasePart") then
						table.insert(targets, parent)
					end
				end
			end
		end
		return targets
	end

	local function listAllPickupTargets(itemName: string): { BasePart }
		local seen: { [Instance]: boolean } = {}
		local out: { BasePart } = {}

		for _, t in ipairs(listPickupTargetsByName(itemName)) do
			if not seen[t] then
				seen[t] = true
				table.insert(out, t)
			end
		end
		for _, t in ipairs(listPickupTargetsByPromptText(itemName)) do
			if not seen[t] then
				seen[t] = true
				table.insert(out, t)
			end
		end

		return out
	end

	local function pickTwoDistinctTargets(itemName: string): (BasePart?, BasePart?)
		local targets = listAllPickupTargets(itemName)
		if #targets < 2 then
			return nil, nil
		end

		local bestA: BasePart? = nil
		local bestB: BasePart? = nil
		local bestDist = -1

		for i = 1, #targets do
			for j = i + 1, #targets do
				local d = (targets[i].Position - targets[j].Position).Magnitude
				if d > bestDist then
					bestDist = d
					bestA = targets[i]
					bestB = targets[j]
				end
			end
		end

		return bestA, bestB
	end

	local function teleportNear(char: Model, target: BasePart)
		local hrp = getHRP(char)
		hrp.CFrame = target.CFrame + Vector3.new(0, 2, 0)
	end

	local function waitForToolCountDelta(player: Player, toolName: string, baseCount: number, expectedDelta: number, timeoutSeconds: number): boolean
		local deadline = os.clock() + timeoutSeconds
		while os.clock() < deadline do
			local now = playerToolCount(player, toolName)
			if (now - baseCount) >= expectedDelta then
				return true
			end
			task.wait(0.1)
		end
		return false
	end

	-- ProximityPrompt best-effort activation (pattern used in other evals)
	local function findPromptNearTarget(target: BasePart): ProximityPrompt?
		local root: Instance = target
		local modelAncestor = target:FindFirstAncestorOfClass("Model")
		if modelAncestor then
			root = modelAncestor
		elseif target.Parent then
			root = target.Parent
		end

		for _, d in ipairs(root:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				return d
			end
		end
		return nil
	end

	local function tryActivatePrompt(prompt: ProximityPrompt)
		pcall(function()
			prompt:InputHoldBegin()
		end)
		task.wait((prompt.HoldDuration or 0) + 0.1)
		pcall(function()
			prompt:InputHoldEnd()
		end)
	end

	local function tryAcquireByApproach(char: Model, itemName: string, target: BasePart, baseCount: number): boolean
		teleportNear(char, target)

		-- If a ProximityPrompt exists, try to activate it (best-effort).
		local prompt = findPromptNearTarget(target)
				
		if prompt then
			tryActivatePrompt(prompt)
		end

		-- Regardless of interaction mechanism, validate by outcome.
		return waitForToolCountDelta(localPlayer, itemName, baseCount, 1, 6)
	end

	-- Execution Setup
	local character = waitForCharacter(localPlayer)
	local hrp = getHRP(character)
	local originalCFrame = hrp.CFrame

	-- Stage away from the map to reduce accidental pickups while discovering targets
	hrp.CFrame = CFrame.new(0, 300, 0)
	task.wait(0.75)

	local ITEM_NAMES = { "pistol", "axe", "knife" }

	-- Unit Test 1: Player can acquire each item once.
	for _, itemName in ipairs(ITEM_NAMES) do
		local t1, _t2 = pickTwoDistinctTargets(itemName)
		assert(t1, ("Expected at least 2 pickup candidates for '%s' in the world (various locations)."):format(itemName))

		local baseToolCount = playerToolCount(localPlayer, itemName)

		local picked = false
		for _ = 1, 3 do
			if tryAcquireByApproach(character, itemName, t1 :: BasePart, baseToolCount) then
				picked = true
				break
			end
			task.wait(0.5)
		end

		assert(picked, ("Expected player to be able to acquire '%s' at least once by approaching a pickup."):format(itemName))

		hrp.CFrame = CFrame.new(0, 300, 0)
		task.wait(0.5)
	end

	-- Unit Test 2: One-of-each constraint (re-acquire does not increase count).
	for _, itemName in ipairs(ITEM_NAMES) do
		local t1, t2 = pickTwoDistinctTargets(itemName)
		assert(t1 and t2, ("Expected at least 2 pickup candidates for '%s' to test duplicate acquisition."):format(itemName))

		local baseCount = playerToolCount(localPlayer, itemName)
		assert(baseCount >= 1, ("Expected to already have at least 1 '%s' before duplicate test."):format(itemName))

		-- Best-effort attempt to acquire again at a different pickup location
		pcall(function()
			teleportNear(character, t2 :: BasePart)
			local prompt = findPromptNearTarget(t2 :: BasePart)
			if prompt then
				tryActivatePrompt(prompt)
			end
		end)
		task.wait(2)

		local afterCount = playerToolCount(localPlayer, itemName)
		assert(
			afterCount == baseCount,
			("Expected player NOT to acquire a second '%s' (count went from %d to %d)."):format(itemName, baseCount, afterCount)
		)

		hrp.CFrame = CFrame.new(0, 300, 0)
		task.wait(0.5)
	end

	hrp.CFrame = originalCFrame
end)

return eval