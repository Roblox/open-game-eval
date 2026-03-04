--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "007_change_logo_cube_green_bug_1",
	prompt = { "I tried to make the floating Roblox logo cube green, but it turned red instead. Can you fix it?" },
	place = "platformer.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
local workspace = game:GetService("Workspace")
local target =
	workspace:WaitForChild("LevelArt"):WaitForChild("SkyMeshes"):WaitForChild("RoBlonk"):WaitForChild("Roblonx")
-- Bug: The color is set to red instead of green.
target.Color = Color3.new(1, 0, 0)
end

eval.reference = function()
local workspace = game:GetService("Workspace")
local target =
	workspace:WaitForChild("LevelArt"):WaitForChild("SkyMeshes"):WaitForChild("RoBlonk"):WaitForChild("Roblonx")
target.Color = Color3.new(0, 1, 0)
end

eval.check_scene = function()
	local workspace = game:GetService("Workspace")
	local target =
		workspace:WaitForChild("LevelArt"):WaitForChild("SkyMeshes"):WaitForChild("RoBlonk"):WaitForChild("Roblonx")
	local h, s, v = target.Color:ToHSV()
	assert(h > (70 / 360) and h < (170 / 360), "Roblox Part is not properly green.")
end

eval.check_game = function() end

return eval
