--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
	scenario_name = "043_platformer_bouncing_jumper",
	prompt = {
		{
			{
				role = "user",
				content = [[Make all OneJump become BounceJump, players will bounce when step on it.]],
				request_id = "s20250804_010"
			}
		}
	},
	place = "platformer.rbxl",
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
end

eval.check_scene = function()
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local jumps = game:GetService("Workspace").LevelArt.Level.Jumps
	assert(jumps:FindFirstChild("BounceJump") and not jumps:FindFirstChild("OneJump"), "Query requires all OneJumps become BounceJumps")
	local player = game:GetService("Players"):GetPlayers()[1] or game:GetService("Players").PlayerAdded:Wait()
	local character = player.character or player.CharacterAdded:Wait()
	task.wait()


	local bounceJumps = 0

	for _, jump in jumps:GetChildren() do
		if jump.Name == "BounceJump"then
			bounceJumps += 1

			local successes = 0

			character:PivotTo(jump["Top_SJ"].CFrame*CFrame.new(0,8,0));

			for i = 1, 20 do
				if successes >= 3 then break end
				successes += successes + (math.abs(player.Character.PrimaryPart.Velocity.Y) >= 0.1 and 1 or 0)
				task.wait(0.5)
			end
			assert(successes >= 3, "Player isn't bouncing on one of the BounceJumps.")
		end
	end

	assert(bounceJumps == 12, "Expecting 12 valid BounceJump objects, since thats how many 'OneJump' objects originally existed.")
end)

return eval
