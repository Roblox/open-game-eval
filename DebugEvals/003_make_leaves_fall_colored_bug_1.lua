--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "003_make_leaves_fall_colored_bug_1",
	prompt = { "I tried to make the leaves on the trees change to autumn colors, but they all turned bright blue and green instead. That doesn't look like fall at all." },
	place = "village.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
local workspace = game:GetService("Workspace")

for _, tree in ipairs(workspace.Trees:GetChildren()) do
	for i, leaf in ipairs(tree:GetChildren()) do
		if leaf.Name:lower() == "leaves" and leaf:IsA("BasePart") then
			-- BUG: The hue is set to a blue/green range, not an autumn range.
			leaf.Color = Color3.fromHSV(
				math.random(120, 240) / 360,
				math.random(40, 100) / 100,
				math.random(40, 100) / 100
			)
		end
	end
end
end

eval.reference = function()
local workspace = game:GetService("Workspace")

for _, tree in ipairs(workspace.Trees:GetChildren()) do
	for i, leaf in ipairs(tree:GetChildren()) do -- It seems this place is set up so all leaves are just within tree and named "Leaves"
		if leaf.Name:lower() == "leaves" and leaf:IsA("BasePart") then
			leaf.Color = Color3.fromHSV(
				(i % 2 == 0 and math.random(0, 55) or math.random(345, 360)) / 360,
				math.random(40, 100) / 100,
				math.random(40, 100) / 100
			)
		end
	end
end
end

eval.check_scene = function()
	local workspace = game:GetService("Workspace")

	local function partIsAutumnColored(part)
		local h, s, v = part.Color:ToHSV()
		-- I looked at a color wheel for a couple minutes and realized all the autumn colors are next to each other in hue
		-- saturation and value should be over 20 to exclude pure black/pure white

		return (h <= 60 / 360 or h >= 340 / 360) and s >= 30 / 100 and v >= 30 / 100
	end

	for _, tree in ipairs(workspace.Trees:GetChildren()) do
		for _, leaf in ipairs(tree:GetChildren()) do -- It seems this place is set up so all leaves are just within tree and named "Leaves"
			if leaf.Name:lower() == "leaves" and leaf:IsA("BasePart") then
				assert(partIsAutumnColored(leaf), `This leaf isn't autumn colored: {leaf}`)
			end
		end
	end
end

eval.check_game = function() end

return eval
