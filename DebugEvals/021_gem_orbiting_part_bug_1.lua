--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "021_gem_orbiting_part_bug_1",
	prompt = { "I tried to make a gem that orbits a part, but the gem isn't showing up in the game at all. It's completely invisible and doesn't seem to exist in the Workspace." },
	place = "baseplate.rbxl"
}

local SelectionContextJson = '[{"instanceName": "OrbitPart", "className": "Part"}]'
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local Workspace = game:GetService("Workspace")

eval.setup = function()
local part = Instance.new("Part")
part.Name = "OrbitPart"
part.Parent = game:GetService("Workspace")
part.Size = Vector3.new(1, 10, 1)
part.Position = Vector3.new(5, 5, 5)
part.CanCollide = true

local SelectionContextJson = '[{"instanceName": "OrbitPart", "className": "Part"}]'
local TableSelectionContext = game:GetService("HttpService"):JSONDecode(SelectionContextJson)

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

-- Buggy implementation
local gem = Instance.new("Part")
gem.Parent = game:GetService("ServerStorage") -- BUG: Parented to ServerStorage
gem.Name = "Gem"
gem.Size = Vector3.one
gem.Shape = Enum.PartType.Ball
gem.Color = Color3.fromRGB(179, 15, 255)
gem.Anchored = true

local gemScript = Instance.new("Script")
gemScript.Source = [[
local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local gem = script.Parent
local orbitPart = workspace:FindFirstChild("OrbitPart",true)

local detectionPart = Instance.new("Part")
detectionPart.Parent = gem
detectionPart.Name = "detection_part"
detectionPart.Color = Color3.fromRGB(255,0,0)
detectionPart.Transparency = 1
detectionPart.Size = Vector3.one * 20
detectionPart.CanCollide = false
detectionPart.CanTouch = true

local target:Model? = nil


RS.PostSimulation:Connect(function(dt: number)
	local targetPosition = target and target:GetPivot().Position or orbitPart.Position
	targetPosition = Vector3.new(targetPosition.X,5,targetPosition.Z)
	gem.Position = gem.Position:Lerp(targetPosition + Vector3.new(math.cos(time()) * 5,0,math.sin(time()) * 5), dt * 3.5)
	detectionPart.Position = gem.Position
	detectionPart.Touched:Connect(function(otherPart: BasePart)
		local model = otherPart:FindFirstAncestorWhichIsA("Model")
		local player:Player = Players:GetPlayerFromCharacter(model)
		if (not player) then return end
		if (target ~= model) then target = model end

	end)
end)
]]
gemScript.Parent = gem
end

eval.reference = function()
local gem = Instance.new("Part")
gem.Parent = workspace
gem.Name = "Gem"
gem.Size = Vector3.one
gem.Shape = Enum.PartType.Ball
gem.Color = Color3.fromRGB(179, 15, 255)
gem.Anchored = true

local gemScript = Instance.new("Script")
gemScript.Source = [[
	local RS = game:GetService("RunService")
local Players = game:GetService("Players")
local gem = script.Parent
local orbitPart = workspace:FindFirstChild("OrbitPart",true)

local detectionPart = Instance.new("Part")
detectionPart.Parent = gem
detectionPart.Name = "detection_part"
detectionPart.Color = Color3.fromRGB(255,0,0)
detectionPart.Transparency = 1
detectionPart.Size = Vector3.one * 20
detectionPart.CanCollide = false
detectionPart.CanTouch = true

local target:Model? = nil


RS.PostSimulation:Connect(function(dt: number)
	local targetPosition = target and target:GetPivot().Position or orbitPart.Position
	targetPosition = Vector3.new(targetPosition.X,5,targetPosition.Z)
	gem.Position = gem.Position:Lerp(targetPosition + Vector3.new(math.cos(time()) * 5,0,math.sin(time()) * 5), dt * 3.5)
	detectionPart.Position = gem.Position
	detectionPart.Touched:Connect(function(otherPart: BasePart)
		local model = otherPart:FindFirstAncestorWhichIsA("Model")
		local player:Player = Players:GetPlayerFromCharacter(model)
		if (not player) then return end
		if (target ~= model) then target = model end

	end)
end)


	]]
gemScript.Parent = gem
end

eval.check_scene = function()
	local function CheckSize(size: Vector3)
		local validSize = true
		local maxSize = 5
		if size.X > maxSize or size.Y > maxSize or size.Z > maxSize then
			validSize = false
		end
		return validSize
	end

	local gem: BasePart = workspace:FindFirstChild("Gem", true)
	assert(gem ~= nil, "Gem not detected in workspace!")
	local validSize = CheckSize(gem.Size)
	assert(validSize == true, `Gem has invalid size: {gem.Size}`)
end

eval.check_game = function()
	local function CheckOrbit(gem: BasePart): boolean
		local orbitPart = Workspace:FindFirstChild("OrbitPart")

		local isOrbiting: boolean = false

		local maxDistance = 15
		local lastPosition = gem.Position
		local lastDistance = (gem.Position - orbitPart.Position).Magnitude

		local validRuns = 0

		for i = 1, 20 do
			task.wait(0.5)

			if gem.Position ~= lastPosition then
				local distance = (gem.Position - orbitPart.Position).Magnitude
				if distance <= maxDistance then
					validRuns += 1
				end
			end

			local distance = (gem.Position - orbitPart.Position).Magnitude
		end

		if validRuns >= 10 then
			isOrbiting = true
		end
		return isOrbiting
	end

	local function CheckFollow(character: Model, gem: BasePart): (boolean, number)
		local targetPosition = gem.Position + Vector3.new(0, 0, 10)
		character:PivotTo(CFrame.new(targetPosition))
		task.wait(1)
		local newTargetPosition = Vector3.new(10, 0, 35)
		character:PivotTo(CFrame.new(newTargetPosition))
		task.wait(3)

		local distance = (gem.Position - character:GetPivot().Position).Magnitude
		local isFollowing = distance <= 10
		return isFollowing, distance
	end

	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()

	local gem: BasePart? = workspace:FindFirstChild("Gem", true)
	local isOrbiting: boolean = CheckOrbit(gem)
	assert(isOrbiting == true, "Gem was not detected orbiting Orbit Part")
	local isFollowing, distance = CheckFollow(character, gem)
	assert(isFollowing == true, `Gem was not detected following character, distance: {distance}`)
end

return eval
