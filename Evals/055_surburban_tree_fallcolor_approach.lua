--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "055_surburban_tree_fallcolor_approach",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make trees change color to red when player approach it.]],
                        request_id = "s20250804_023"
                    }
                }
            },
    place = "surburban.rbxl",

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
	local trees = game:GetService("Workspace").Trees
	local players = game:GetService("Players")
    local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
    player:LoadCharacter()
    local character = player.Character or player.CharacterAdded:Wait()

	local function treeIsRed(tree)
		for _, leaf in tree:GetDescendants() do
			if leaf:IsA("BasePart") and leaf.Parent.Name == "Leaves" then
				local h, s, v = leaf.Color:ToHSV()
				local out = h * 360 < 15 or h * 360 > 340 -- red hue
				out = out and s * 100 > 30 and v * 100 > 30 -- needs some sat/val

				if not out then
					return false
				end
			end
		end

		return true
	end

	for _, tree in trees:GetChildren() do
		assert(not treeIsRed(tree), "A tree started red.")
	end

	for _, tree in trees:GetChildren() do
		character:PivotTo(tree:GetPivot())
		task.wait(0.5)
		assert(treeIsRed(tree), "Tree is not red despite being next to it.")
	end

	character:PivotTo(game:GetService("Workspace").SpawnLocation.CFrame)

	task.wait(0.2)

	for _, tree in trees:GetChildren() do
		assert(not treeIsRed(tree), "Trees haven't reverted to red.")
	end
end

return eval
