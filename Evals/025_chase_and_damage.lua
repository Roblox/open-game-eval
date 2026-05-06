--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "025_chase_and_damage",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[make an entity that chase and damage the player]],
                        request_id = "s20250722_011"
                    }
                }
            },
    place = "baseplate.rbxl"

}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local Workspace = game:GetService("Workspace")
local OldState = Workspace:GetDescendants()

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


	local newScript = Instance.new("Script")
	newScript.Source = [[
	local remote = Instance.new("RemoteEvent")
	remote.Name = "UpdateHP"
	remote.OnServerEvent:Connect(function(plr:Player, godMode:boolean)
		if not plr.Character then return end
		local h:Humanoid? = plr.Character:FindFirstChildWhichIsA("Humanoid")

		if not h then return end

		if godMode then
			h.Health = math.huge
			h.MaxHealth = math.huge
		else
			h.Health = 100
			h.MaxHealth = 100
		end
	end)
	remote.Parent = game:GetService("ReplicatedStorage")]]
	newScript.Parent = game:GetService("ServerScriptService")

end

eval.reference = function()
end

eval.check_scene = function()
end

eval.check_game = function()
	local humanoids = {}
	local healthChanger:RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("UpdateHP", math.huge)

	for _, obj:any in utils_he.table_difference(OldState, Workspace:GetDescendants()) do
		-- Humanoids are expected to be placed within models
		if obj:IsA("Humanoid") and obj.Parent:IsA("Model") then
			-- I was having problems with GetPivot not updating because a PrimaryPart wasn't set.
			if not obj.Parent.PrimaryPart then
				for _, v in pairs(obj.Parent:GetChildren()) do
					if v:IsA("BasePart") and v.Anchored == false then
						obj.Parent.PrimaryPart = v
						break
					end
				end

				if not obj.Parent.PrimaryPart then continue end

			end
			table.insert(humanoids, obj.Parent)
		end
	end

	assert(#humanoids > 0, "No new humanoids were added.")

	-- Checks for stuff like parts existing are implied in pivot changes
	-- A model's pivot is found through its parts

	local players = game:GetService("Players")
	local player = if #players:GetPlayers() > 0 then players:GetPlayers()[1] else players.PlayerAdded:Wait()
    if not player.Character then
        player:LoadCharacter()
    end
	local character = player.Character

	while not character.PrimaryPart do task.wait() end

	local plrHumanoid = character:WaitForChild("Humanoid", math.huge)
	healthChanger:FireServer(true)

	local function squareDist(v1:CFrame, v2:CFrame)
		-- In games I've worked on, sqrt sometimes is so inefficient that
		-- I've found in situations where squared distance is enough
		-- I just go with that instead, I know it sounds crazy tho

		return (v1.X - v2.X)^2 + (v1.Y - v2.Y)^2 + (v1.Z - v2.Z)^2
	end

	-- check movement

	assert((function()
		for _ = 1, 20 do
			local cfRecord = {}
			local moveSuccesses = {}
			local newPlayerPos = CFrame.new(
				math.random(-10_000, 10_000) / 100, -- [-100, 100] but with 100th precision
				0.5,
				math.random(-10_000, 10_000) / 100
			)

			character:PivotTo(newPlayerPos)
			local playerPos = character:GetPivot()

			for _, potentialZombie in humanoids do
				cfRecord[potentialZombie] = squareDist(playerPos, potentialZombie:GetPivot())
				moveSuccesses[potentialZombie] = 0
			end

			local movementSuccess = false

			for _ = 1, 600 do -- 30s potential total
				for _, potentialZombie in humanoids do
					local newDist = squareDist(playerPos, potentialZombie:GetPivot())
					if newDist < cfRecord[potentialZombie] then
						moveSuccesses[potentialZombie] += 1
						cfRecord[potentialZombie] = newDist

						if moveSuccesses[potentialZombie] > 10 then
							movementSuccess = true
							break
						end
					end
				end

				if movementSuccess then break end

				task.wait(0.05)
			end
			assert(movementSuccess, "NPCs failed to move to player in specific instance.")
			if not movementSuccess then return false end
		end
		return true
	end)(), "NPCs aren't moving towards the player")

	-- Movement was a success

	-- Damage check
	healthChanger:FireServer(false)

	local damageSuccess = false

	for i = 1, 200 do
		for _, potentialZombie in humanoids do

			if plrHumanoid.Health < 100 then
				damageSuccess = true
				break
			end

			character:PivotTo(potentialZombie:GetPivot() + Vector3.new(2,0,0))
			task.wait(0.5)
		end
		task.wait()
	end

	assert(damageSuccess, "Damage was not detected from the NPCs.")


	print("Check game was a success.")
end

return eval
