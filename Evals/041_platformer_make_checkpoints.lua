--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "041_platformer_make_checkpoints",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make this a checkpoint when player step on it.]],
                        request_id = "s20250804_008"
                    }
                }
            },
    place = "platformer.rbxl",
}

local SelectionContextJson = "[{\"instanceName\": \"OneJump\", \"className\": \"Model\"}]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local Workspace = game:GetService("Workspace")


eval.setup = function()

	local selected = utils_he.GetSelected(TableSelectionContext)
	print(selected)

end

eval.reference = function()
end

eval.check_scene = function()
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local players = game:GetService("Players")
	local respawnTime = players.RespawnTime

	local player = players:GetPlayers()[1] or players.PlayerAdded:Wait()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid")
	print("humanoid", humanoid)

	player.CharacterAdded:Connect(function(newCharacter: Model)
		character = newCharacter
		humanoid = character:WaitForChild("Humanoid")
	end)

	local function TestRespawnNoTouch()
		print("TestRespawnNoTouch", humanoid)
		humanoid.Health = 0
		task.wait(respawnTime + 1)
		local defSpawnLocation = Workspace.SpawnLocation.Position
		local spawnedLocation = character:GetPivot().Position

		local distance = (defSpawnLocation - spawnedLocation).Magnitude
		assert(distance < 7.5, `Player was not spawned at the default spawn location: {distance}`)

	end

	local function TestRespawnTouch()
		local target = utils_he.GetSelected(TableSelectionContext)[1] :: PVInstance

		local targetFrame = target:GetPivot() + Vector3.yAxis * (humanoid.HipHeight + 2)
		character:PivotTo(targetFrame)
		task.wait(1)
		humanoid.Health = 0
		task.wait(respawnTime + 1)
		local goalSpawnedPosition = target:GetPivot().Position
		local spawnedPosition = character:GetPivot().Position

		local distance = (goalSpawnedPosition - spawnedPosition).Magnitude
		assert(distance <= 7.5,`Character did not spawn near checkpoint! Distance:{distance}`)
	end

	TestRespawnNoTouch()
	TestRespawnTouch()


end)

return eval
