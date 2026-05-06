--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
    scenario_name = "013_inf_cube_fall",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[make it so that a size 1,1,1 cube falls at position 0,0,0 every second]],
                        request_id = "s20250626_015"
                    }
                }
            },
    place = "baseplate.rbxl"

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

eval.check_game = function()
	local workspace = game:GetService("Workspace")
	local players = game:GetService("Players")
	local player = if #players:GetPlayers() > 0 then players:GetPlayers()[1] else players.PlayerAdded:Wait()
	player:LoadCharacter()
	local char = player.Character or player.CharacterAdded:Wait()
	char:PivotTo(CFrame.new(0,0,20)) -- character might get in the way

	local marked = {}
	local total = 0

	local function count()

		for _, v in ipairs(workspace:GetDescendants()) do
			if not marked[v] and v:IsA("BasePart") and v.Anchored == false and v.Size == Vector3.new(1,1,1) then
				if (Vector3.new(v.CFrame.p.X, 0, v.CFrame.p.Z)-Vector3.new(0,0,0)).Magnitude < 5 then
					marked[v] = true
					total+=1
				end
			end
		end

		for part, _ in pairs(marked) do -- problem where the pile of parts is making it impossible to count new parts as they roll off the stack
			part:Destroy()
		end
	end

	count()

	local successes = 0

	for i = 3, 8 do -- 5 attempts
		count()
		local expected = total+i
		task.wait(i)
		count()
		print("data", expected, total)
		successes += (total<=expected+1 and total>=expected-1) and 1 or 0 -- Worried that timers starting at different times might make the count inaccurate so we allow for 1 extra or missing part.
	end

	assert(successes > 1, "Requires at least 2 successesful part creations.")

end

return eval
