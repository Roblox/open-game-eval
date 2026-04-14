--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
local types, utils_runs, utils_he, lib
if LoadedCode:FindFirstChild("EvalUtils") then
	types = require(LoadedCode.EvalUtils.types)
	utils_runs = require(LoadedCode.EvalUtils.utils_runs)
	utils_he = require(LoadedCode.EvalUtils.utils_he)
	lib = require(LoadedCode.EvalUtils.lib)
else
	local types = require(game.LoadedCode.types)
end
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
	scenario_name = "122_animal_item_with_rarity",
	prompt = {
		{
			{
				role = "user",
				content = [[I want 6 items of different rarity to spawn in the middle, each item must have a unique animal shape.

Rarity with random income between two values for each rarity: Common 60% $1-5, Rare 20% $6-50, Very Rare 11% $100-1,000, Mythic 7% $1,000-10,000, Legendary 1% $10,000-50,000, Ultra 0.9% $50,000-100,000, God 0.09% $100,000-300,000, Limited 0.01% Random value between $300,000-500,000.

6 items spawn on the map and must slide on the conveyor belt (already installed) from {spawn=Vector3.new(0,0,0), platform=Vector3.new(-56,0,0)}, {spawn=Vector3.new(0,0,0), platform=Vector3.new(-28,0,-48.497)}, {spawn=Vector3.new(0,0,0), platform=Vector3.new(28,0,-48.497)}, {spawn=Vector3.new(0,0,0), platform=Vector3.new(56,0,0)}, {spawn=Vector3.new(0,0,0), platform=Vector3.new(28,0,48.497)}, {spawn=Vector3.new(0,0,0), platform=Vector3.new(-28,0,48.497)}.

The sliding time must be 10 seconds then it remains stationary for 30 seconds before disappearing.

1 second later, 6 new items spawn randomly (respecting spawn rates) with 3 items per animal rarity.

The font must adhere to this -- Billboard (name + rarity):

'local billboard = Instance.new("BillboardGui"); billboard.Size = UDim2.new(0, 200, 0, 50); billboard.StudsOffset = Vector3.new(0, 3, 0); billboard.AlwaysOnTop = true; billboard.Parent = main; local textLabel = Instance.new("TextLabel"); textLabel.Size = UDim2.new(1, 0, 1, 0); textLabel.BackgroundTransparency = 1; textLabel.Text = name .. " [" .. rarity .. "]"; textLabel.TextScaled = true; textLabel.TextColor3 = Color3.new(1, 1, 1); textLabel.Parent = billboard.
'
Each animal must have a unique cubic Minecraft-style shape that reflects its true form. Here are the 24 animals:

Common (60%) Cow Sheep Chicken

Rare (20%) Wolf Pig Horse

Very Rare (11%) Tiger Bear Elephant

Mythic (7%) Unicorn Phoenix Griffin

Legendary (1%) Dragon Minotaur Hydra

Ultra (0.9%) Titan Celestial Leviathan

God (0.09%) GodSword DivineShield HolyOrb

Limited (0.01%) Excalibur LegendaryGem DivineStaff.

Create designs that reflect the item names. The items must float on the conveyor at the size of a Roblox player's head.]],
				
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

	-- Updating setup function to include conveyors and platforms mentioned in the prompt.
	local function buildConveyorBelt(name: string, orientation: string, speed: number, platform: Part, extraSize: number)
		local conveyorBelt = Instance.new("Part")
		conveyorBelt.Name = name
		conveyorBelt.Color = Color3.fromRGB(27, 42, 53)
		conveyorBelt.Parent = game:GetService("Workspace")
		conveyorBelt.Anchored = true

		if orientation == "left"  then
			conveyorBelt.Orientation = Vector3.new(0, -90, 0)
			if platform  then
				conveyorBelt.Size = Vector3.new(8, 1, platform.Position.X - platform.Size.Z + (extraSize or 0))
				conveyorBelt.Position = Vector3.new(
					platform.Position.X - (conveyorBelt.Size.Z / 2) - (platform.Size.Z / 2),
					platform.Position.Y,
					platform.Position.Z
				)
			end
		elseif orientation == "right" then
			conveyorBelt.Orientation = Vector3.new(0, 90, 0)
			if platform  then
				conveyorBelt.Size = Vector3.new(8, 1, -platform.Position.X - platform.Size.Z + (extraSize or 0))
				conveyorBelt.Position = Vector3.new(
					platform.Position.X + (conveyorBelt.Size.Z / 2) + (platform.Size.Z / 2),
					platform.Position.Y,
					platform.Position.Z
				)
			end
		end

		local conveyorTexture = Instance.new("Texture")
		conveyorTexture.Parent = conveyorBelt
		conveyorTexture.ColorMapContent = Content.fromAssetId(16848361091)
		conveyorTexture.OffsetStudsU = 0.5
		conveyorTexture.StudsPerTileU = 9
		conveyorTexture.StudsPerTileV = 6
		conveyorTexture.Face = Enum.NormalId.Top

		local conveyorScript = Instance.new("Script")
		conveyorScript.Parent = conveyorBelt
		conveyorScript.Enabled = true
		conveyorScript.Source = [[
local TweenService = game:GetService("TweenService")
local ConveyorBelt = script.Parent
local Speed = ConveyorBelt.Size.Z / ]] .. speed .. "\n" .. [[
local texture = ConveyorBelt.Texture

ConveyorBelt.AssemblyLinearVelocity = ConveyorBelt.CFrame.LookVector * Speed

local info = TweenInfo.new(60, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1)
local tween = TweenService:Create(texture, info, {OffsetStudsV = Speed*-60})
tween:Play()
		]]
		return conveyorBelt
	end

	local function buildPlatform(name: string, position: Vector3)
		local platform = Instance.new("Part")
		platform.Name = name
		platform.Parent = game:GetService("Workspace")
		platform.Size = Vector3.new(8, 1, 8)
		platform.Position = position
		platform.Anchored = true

		return platform
	end

	local platforms = {
		PlatformOne = buildPlatform("PlatformOne", Vector3.new(-56,0,0)),
		PlatformTwo = buildPlatform("PlatformTwo", Vector3.new(-28,0,-48.497)),
		PlatformThree = buildPlatform("PlatformThree", Vector3.new(28,0,-48.497)),
		PlatformFour = buildPlatform("PlatformFour", Vector3.new(56,0,0)),
		PlatformFive = buildPlatform("PlatformFive", Vector3.new(28,0,48.497)),
		PlatformSix = buildPlatform("PlatformSix", Vector3.new(-28,0,48.497)),
	}


	buildConveyorBelt("ConveyorBeltOne", "right", 10, platforms.PlatformOne)
	buildConveyorBelt("ConveyorBeltTwoA", "right", 5, platforms.PlatformTwo, platforms.PlatformTwo.Size.Z / 2)
	buildConveyorBelt("ConveyorBeltTwoB", "left", 5, platforms.PlatformThree, platforms.PlatformThree.Size.Z / 2)
	buildConveyorBelt("ConveyorBeltThree", "left", 10, platforms.PlatformFour)
	buildConveyorBelt("ConveyorBeltFourA", "left", 5, platforms.PlatformFive, platforms.PlatformFive.Size.Z / 2)
	buildConveyorBelt("ConveyorBeltFourB", "right", 5, platforms.PlatformSix, platforms.PlatformSix.Size.Z / 2)

	local conveyorTwo = buildConveyorBelt("ConveyorBeltTwo", "", 5)
	conveyorTwo.Position = Vector3.new(0, 0, -25.5)
	conveyorTwo.Size = Vector3.new(8, 1, 39)
	conveyorTwo.Orientation = Vector3.new(0, 0, 0)

	local conveyorFour = buildConveyorBelt("ConveyorBeltFour", "", 5)
	conveyorFour.Position = Vector3.new(0, 0, 25.5)
	conveyorFour.Size = Vector3.new(8, 1, 39)
	conveyorFour.Orientation = Vector3.new(0, 180, 0)
end

eval.reference = function()
	local script = Instance.new("Script")
	script.Parent = game:GetService("ServerScriptService")
	script.Name = "spawnAnimals"
	script.Enabled = true
	script.Source = [[
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local AnimalSize = 1.2

function createAnimal(name: string)
	local animal = Instance.new("Part")
	animal.Name = name
	animal.Size = Vector3.new(AnimalSize, AnimalSize, AnimalSize)
	
	if name == "Cow" then
		animal.Color = Color3.fromRGB(0, 0, 0)
	elseif name == "Sheep" then
		animal.Color = Color3.fromRGB(255, 255, 255)
	elseif name == "Chicken" then
		animal.Color = Color3.fromRGB(246, 213, 90)
	elseif name == "Wolf" then
		animal.Color = Color3.fromRGB(124, 126, 124)
	elseif name == "Pig" then
		animal.Color = Color3.fromRGB(246, 182, 210)
	elseif name == "Horse" then
		animal.Color = Color3.fromRGB(159, 81, 45)
	elseif name == "Tiger" then
		animal.Color = Color3.fromRGB(244, 123, 31)
	elseif name == "Bear" then
		animal.Color = Color3.fromRGB(106, 78, 57)
	elseif name == "Elephant" then
		animal.Color = Color3.fromRGB(168, 179, 177)
	elseif name == "Unicorn" then
		animal.Color = Color3.fromRGB(241, 167, 213)
	elseif name == "Phoenix" then
		animal.Color = Color3.fromRGB(255, 113, 61)
	elseif name == "Griffin" then
		animal.Color = Color3.fromRGB(231, 169, 110)
	elseif name == "Dragon" then
		animal.Color = Color3.fromRGB(255, 0, 0)
	elseif name == "Minotaur" then
		animal.Color = Color3.fromRGB(110, 159, 60)
	elseif name == "Hydra" then
		animal.Color = Color3.fromRGB(0, 126, 148)
	elseif name == "Titan" or name == "Celestial" or name == "Leviathan" then
		animal.Color = Color3.fromRGB(31, 58, 96)
	elseif name == "GodSword" or name == "DivineShield" or name == "HolyOrb" then
		animal.Color = Color3.fromRGB(168, 168, 168)
	elseif name == "Excalibur" or name == "LegendaryGem" or name == "DivineStaff" then
		animal.Color = Color3.fromRGB(255, 217, 0)
	end
	
	return animal
end

local frequencyLimited   = 0.0001
local frequencyGod       = 0.0009 + frequencyLimited
local frequencyUltra     = 0.009  + frequencyGod
local frequencyLegendary = 0.01   + frequencyUltra
local frequencyMythic    = 0.07   + frequencyLegendary
local frequencyVeryRare  = 0.11   + frequencyMythic
local frequencyRare      = 0.2    + frequencyVeryRare
local frequencyCommon    = 0.6    + frequencyRare

local rarities = {
	{
		Name = "Common",
		Frequency = frequencyCommon,
		MinIncome = 1,
		MaxIncome = 5,
		Animals = { createAnimal("Cow"), createAnimal("Sheep"), createAnimal("Chicken") },
	},
	{
		Name = "Rare",
		Frequency = frequencyRare,
		MinIncome = 6,
		MaxIncome = 50,
		Animals = { createAnimal("Wolf"), createAnimal("Pig"), createAnimal("Horse") },
	},
	{
		Name = "Very Rare",
		Frequency = frequencyVeryRare,
		MinIncome = 100,
		MaxIncome = 1_000,
		Animals = { createAnimal("Tiger"), createAnimal("Bear"), createAnimal("Elephant") },
	},
	{
		Name = "Mythic",
		Frequency = frequencyMythic,
		MinIncome = 1_000,
		MaxIncome = 10_000,
		Animals = { createAnimal("Unicorn"), createAnimal("Phoenix"), createAnimal("Griffin") },
	},
	{
		Name = "Legendary",
		Frequency = frequencyLegendary,
		MinIncome = 10_000,
		MaxIncome = 50_000,
		Animals = { createAnimal("Dragon"), createAnimal("Minotaur"), createAnimal("Hydra") },
	},
	{
		Name = "Ultra",
		Frequency = frequencyUltra,
		MinIncome = 50_000,
		MaxIncome = 100_000,
		Animals = { createAnimal("Titan"), createAnimal("Celestial"), createAnimal("Leviathan") },
	},
	{
		Name = "God",
		Frequency = frequencyGod,
		MinIncome = 100_000,
		MaxIncome = 300_000,
		Animals = { createAnimal("GodSword"), createAnimal("DivineShield"), createAnimal("HolyOrb") },
	},
	{
		Name = "Limited",
		Frequency = frequencyLimited,
		MinIncome = 300_000,
		MaxIncome = 500_000,
		Animals = { createAnimal("Excalibur"), createAnimal("LegendaryGem"), createAnimal("DivineStaff") },
	},
}


local conveyors = {
	ConveyorOne = Workspace:FindFirstChild("ConveyorBeltOne"),
	ConveyorTwo = Workspace:FindFirstChild("ConveyorBeltTwo"),
	ConveyorThree = Workspace:FindFirstChild("ConveyorBeltThree"),
	ConveyorFour = Workspace:FindFirstChild("ConveyorBeltFour"),
}

local conveyorStartPositions = {
	Vector3.new(
		conveyors.ConveyorOne.Position.X + conveyors.ConveyorOne.Size.Z / 2 - 4 - AnimalSize,
		AnimalSize,
		conveyors.ConveyorOne.Position.Z
	),
	Vector3.new(
		conveyors.ConveyorTwo.Position.X - conveyors.ConveyorTwo.Size.X / 5,
		AnimalSize,
		conveyors.ConveyorTwo.Position.Z + conveyors.ConveyorTwo.Size.Z / 2 - AnimalSize
	),
	Vector3.new(
		conveyors.ConveyorTwo.Position.X + conveyors.ConveyorTwo.Size.X / 5,
		AnimalSize,
		conveyors.ConveyorTwo.Position.Z + conveyors.ConveyorTwo.Size.Z / 2 - AnimalSize
	),
	Vector3.new(
		conveyors.ConveyorThree.Position.X - conveyors.ConveyorThree.Size.Z / 2 + 4 + AnimalSize,
		AnimalSize,
		conveyors.ConveyorThree.Position.Z
	),
	Vector3.new(
		conveyors.ConveyorFour.Position.X + conveyors.ConveyorFour.Size.X / 5,
		AnimalSize,
		conveyors.ConveyorFour.Position.Z - conveyors.ConveyorFour.Size.Z / 2 + AnimalSize
	),
	Vector3.new(
		conveyors.ConveyorFour.Position.X - conveyors.ConveyorFour.Size.X / 5,
		AnimalSize,
		conveyors.ConveyorFour.Position.Z - conveyors.ConveyorFour.Size.Z / 2 + AnimalSize
	),
}


function randomFloat(lower, greater)
	return lower + math.random()  * (greater - lower);
end

local currentThread
local currentAnimals = {}

function doesEveryPlatformContainNAnimals(numberOfItems: number)
	local platforms = {
		Workspace:FindFirstChild("PlatformOne"),
		Workspace:FindFirstChild("PlatformTwo"),
		Workspace:FindFirstChild("PlatformThree"),
		Workspace:FindFirstChild("PlatformFour"),
		Workspace:FindFirstChild("PlatformFive"),
		Workspace:FindFirstChild("PlatformSix"),
	}

	-- Test that after 10 seconds each platform has one touching animal.
	for _, platform in pairs(platforms) do
		local animalsTouchingPlatform = 0
		for _, v in pairs(platform:GetTouchingParts()) do
			if table.find(currentAnimals, v) then
				animalsTouchingPlatform += 1
			end
		end

		if animalsTouchingPlatform ~= numberOfItems then
			return false
		end
	end

	return true
end

function spawnAnimals()
	if currentThread and currentThread ~= coroutine.running() then
		task.cancel(currentThread)
	end
	
	-- Destroy current animals, if any.
	for _, animal in pairs(currentAnimals) do
		animal:Destroy()
	end
	currentAnimals = {}
	
	task.wait(1)
	
	for i = 1,6,1 do
		local randomNumber = randomFloat(0.0001, 1)
		local rarity = nil
		for i = #rarities, 1, -1 do
			if randomNumber <= rarities[i].Frequency then
				rarity = rarities[i]
				break
			end
		end
		local randomAnimal = rarity.Animals[math.random(1, #rarity.Animals)]:Clone()
		randomAnimal.Parent = Workspace

		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(0, 200, 0, 50)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = randomAnimal

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = randomAnimal.Name .. " [" .. rarity.Name .. "]"
		textLabel.TextScaled = true
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.Parent = billboard

		randomAnimal.Position = conveyorStartPositions[i]
		table.insert(currentAnimals, randomAnimal)
	end

	local platformPositions = {
		Workspace:FindFirstChild("PlatformOne").Position,
		Workspace:FindFirstChild("PlatformTwo").Position,
		Workspace:FindFirstChild("PlatformThree").Position,
		Workspace:FindFirstChild("PlatformFour").Position,
		Workspace:FindFirstChild("PlatformFive").Position,
		Workspace:FindFirstChild("PlatformSix").Position,
	}
	for i, animal in currentAnimals do
		local targetPos = platformPositions[i] + Vector3.new(0, AnimalSize / 2 + 0.5, 0)
		animal.Anchored = true
		local tween = TweenService:Create(animal, TweenInfo.new(10, Enum.EasingStyle.Linear), {Position = targetPos})
		tween:Play()
	end

	task.wait(10)
	currentThread = task.delay(30, spawnAnimals)
end

spawnAnimals()
]]
end

eval.check_scene = function()

end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	local workspace = game:GetService("Workspace")

	local function isValidAnimal(text: string)
		return (
			text == "Cow [Common]" or
				text == "Sheep [Common]" or
				text == "Chicken [Common]" or
				text == "Wolf [Rare]" or
				text == "Pig [Rare]" or
				text == "Horse [Rare]" or
				text == "Tiger [Very Rare]" or
				text == "Bear [Very Rare]" or
				text == "Elephant [Very Rare]" or
				text == "Unicorn [Mythic]" or
				text == "Phoenix [Mythic]" or
				text == "Griffin [Mythic]" or
				text == "Dragon [Legendary]" or
				text == "Minotaur [Legendary]" or
				text == "Hydra [Legendary]" or
				text == "Titan [Ultra]" or
				text == "Celestial [Ultra]" or
				text == "Leviathan [Ultra]" or
				text == "GodSword [God]" or
				text == "DivineShield [God]" or
				text == "HolyOrb [God]" or
				text == "Excalibur [Limited]" or
				text == "LegendaryGem [Limited]" or
				text == "DivineStaff [Limited]"
		)

	end

	local function getAnimalsInWorkspace()
		local animals = {}
		for _, obj in pairs(workspace:GetDescendants()) do
			if obj:IsA("BillboardGui") then
				if isValidAnimal(obj.TextLabel.Text) then
					table.insert(animals, obj.Parent)
				end
			end
		end
		return animals
	end

  task.wait(1)

	local animals = getAnimalsInWorkspace()
	assert(#animals == 6, "Should spawn 6 animals on the map")

	local areAllAnimalsIdentical = true
	for i = 1,#animals,1 do
		local billboardGui = animals[i].BillboardGui
		-- Validate the properties of the BillboardGui match the requirements from the prompt.
		assert(billboardGui.Size == UDim2.new(0, 200, 0, 50), "[BillboardGui] Size should match requirement from prompt")
		assert(billboardGui.StudsOffset == Vector3.new(0, 3, 0), "[BillboardGui] StudsOffset should match requirement from prompt")
		assert(billboardGui.AlwaysOnTop, "[BillboardGui] AlwaysOnTop should match requirement from prompt")

		-- Validate the properties of the BillboardGui.TextLabel match the requirements from the prompt.
		assert(billboardGui.TextLabel.Size == UDim2.new(1, 0, 1, 0), "[BillboardGui.TextLabel] Size should match requirement from prompt")
		assert(billboardGui.TextLabel.BackgroundTransparency == 1, "[BillboardGui.TextLabel] BackgroundTransparency should match requirement from prompt")
		assert(billboardGui.TextLabel.TextScaled, "[BillboardGui.TextLabel] TextScaled should match requirement from prompt")
		assert(billboardGui.TextLabel.TextColor3 == Color3.new(1, 1, 1), "[BillboardGui.TextLabel] TextColor3 should match requirement from prompt")

		if billboardGui.TextLabel.Text ~= animals[1].BillboardGui.TextLabel.Text then
			areAllAnimalsIdentical = false
			break
		end
	end

	-- Though it could happen that all animals are identical I still add
	-- this test, because if they are that's a big red flag.
	assert(not areAllAnimalsIdentical, "All of the spawned animals are identical")

	-- Wait 10 seconds + a buffer for items to reach their final positions.
	task.wait(10 + 2)

	local PROXIMITY_THRESHOLD = 8

	local function doesEveryPlatformContainNAnimals(numberOfItems: number)
		local animals = getAnimalsInWorkspace()

		local platforms = {
			workspace:FindFirstChild("PlatformOne"),
			workspace:FindFirstChild("PlatformTwo"),
			workspace:FindFirstChild("PlatformThree"),
			workspace:FindFirstChild("PlatformFour"),
			workspace:FindFirstChild("PlatformFive"),
			workspace:FindFirstChild("PlatformSix"),
		}

		for _, platform in pairs(platforms) do
			local animalsNearPlatform = 0
			for _, animal in pairs(animals) do
				local dist = (animal.Position - platform.Position).Magnitude
				if dist < PROXIMITY_THRESHOLD then
					animalsNearPlatform += 1
				end
			end

			if animalsNearPlatform ~= numberOfItems then
				return false
			end
		end

		return true
	end

	assert(doesEveryPlatformContainNAnimals(1), "Every platform must have exactly one touching animal")

	-- Animals rest at the platforms for 30 seconds, then they get destroyed,
	-- then after 1 second new animals are spawned in the middle.
	task.wait(31)

	local animals = getAnimalsInWorkspace()
	assert(#animals == 6, "Should remove old animals and spawn 6 new after 31 seconds")

	-- Test that old animals are no longer touching the platforms
	assert(doesEveryPlatformContainNAnimals(0), "No animals should have reached the platforms yet")

	print("Success.")
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)

end)

return eval
