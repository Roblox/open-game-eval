--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "007_change_logo_cube_green_bug_2",
	prompt = { "I'm trying to change the color of the big floating Roblox logo cube to green, but it keeps turning red right after I change it. It seems like some other script is interfering and overriding the color." },
	place = "platformer.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
local buggyScript = Instance.new("Script")
buggyScript.Name = "Reset"
buggyScript.Parent = game:GetService("ServerScriptService")

buggyScript.Source = [[
	local workspace = game:GetService("Workspace")
	local target = workspace:WaitForChild("LevelArt"):WaitForChild("SkyMeshes"):WaitForChild("RoBlonk"):WaitForChild("Roblonx")
	
	while task.wait(0.5) do
		if target then
			target.Color = Color3.new(1, 0, 0) -- Set to red
		end
	end
]]

end

eval.reference = function()
-- First, find and remove the script causing the interference.
local buggyScript = game:GetService("ServerScriptService"):FindFirstChild("ColorResetBug")
if buggyScript then
	buggyScript:Destroy()
end

-- Now, apply the correct color change.
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
