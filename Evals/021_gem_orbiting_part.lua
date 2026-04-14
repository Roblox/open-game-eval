--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
    scenario_name = "021_gem_orbiting_part",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make a gem orbit around this part, and automatically attract towards the player when they are within 10 studs.]],
                        request_id = "s20250722_007"
                    }
                }
            },
    place = "baseplate.rbxl",

local SelectionContextJson = "[{\"instanceName\": \"OrbitPart\", \"className\": \"Part\"}]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local Workspace = game:GetService("Workspace")


eval.setup = function()

    local part = Instance.new('Part')
    part.Name = 'OrbitPart'
    part.Parent = game:GetService('Workspace')
    part.Size = Vector3.new(1, 10, 1)
    part.Position = Vector3.new(5, 5, 5)
    part.CanCollide = true

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
end

eval.check_scene = function()

	local function CheckSize(size:Vector3)
		local validSize = true
		local maxSize = 5
		if (size.X > maxSize or size.Y > maxSize or size.Z > maxSize) then validSize = false end
		return validSize
	end


	local gem:BasePart = workspace:FindFirstChild("Gem",true)
	assert(gem ~= nil, "Gem not detected in workspace!")
	local validSize = CheckSize(gem.Size)
	assert(validSize == true,`Gem has invalid size: {gem.Size}`)




end

eval.check_game = function()

	local function CheckOrbit(gem:BasePart):boolean
		local orbitPart = Workspace:FindFirstChild("OrbitPart")

		local isOrbiting:boolean = false

		local maxDistance = 15
		local lastPosition = gem.Position
		local lastDistance = (gem.Position - orbitPart.Position).Magnitude

		local validRuns = 0

		for i = 1, 20 do
			task.wait(0.5)

			if (gem.Position ~= lastPosition) then
				local distance = (gem.Position - orbitPart.Position).Magnitude
				if (distance <= maxDistance) then
					validRuns += 1
				end
			end

			local distance = (gem.Position - orbitPart.Position).Magnitude
		end

		if (validRuns >= 10) then
			isOrbiting = true
		end
		return isOrbiting
	end

	local function CheckFollow(character:Model,gem:BasePart):(boolean,number)
		local targetPosition = gem.Position + Vector3.new(0,0,10)
		character:PivotTo(CFrame.new(targetPosition))
		task.wait(1)
		local newTargetPosition = Vector3.new(10,0,35)
		character:PivotTo(CFrame.new(newTargetPosition))
		task.wait(3)

		local distance = (gem.Position - character:GetPivot().Position).Magnitude
		local isFollowing = distance <= 10
		return isFollowing,distance
	end

	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()

	local gem:BasePart? = workspace:FindFirstChild("Gem",true)
	local isOrbiting:boolean = CheckOrbit(gem)
	assert(isOrbiting == true, "Gem was not detected orbiting Orbit Part")
	local isFollowing,distance = CheckFollow(character,gem)
	assert(isFollowing == true, `Gem was not detected following character, distance: {distance}`)

end

return eval
