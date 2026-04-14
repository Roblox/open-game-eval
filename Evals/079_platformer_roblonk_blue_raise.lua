--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "079_platformer_roblonk_blue_raise",
	prompt = {
		{
			{
				role = "user",
				content = [[Make the Roblonk Model blue and raise by 5 studs smoothly when touchiung it, and then back to normal when you stop touching it]],
				request_id = "s20250825_009",
			},
		},
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
	local workspace = game:GetService("Workspace")
	local roblonk = workspace.LevelArt.SkyMeshes.RoBlonk
	local trigger = Instance.new("Part")
	trigger.Transparency = 1
	trigger.CanCollide = false
	trigger.Size = roblonk.Roblonx.Size + Vector3.new(3, 3, 3)
	trigger.CFrame = roblonk.Roblonx.CFrame
	local weld = Instance.new("Weld")
	weld.Part0 = trigger
	weld.Part1 = roblonk.Roblonx
	weld.Parent = trigger
	local touchScript = Instance.new("Script")
	touchScript.Source = [[
local tweenService = game:GetService("TweenService");

local roblonx = script.Parent.Parent.Roblonx;
local anchor = script.Parent.Parent.Roblonx.anchor;

local touchingPart = nil;

local tweenTouch = tweenService:Create(roblonx, TweenInfo.new(2, Enum.EasingStyle.Linear), {Color = Color3.new(0,0,1)});
local tweenTouchAnchor = tweenService:Create(anchor, TweenInfo.new(2, Enum.EasingStyle.Linear), {CFrame = anchor.CFrame*CFrame.new(0,5,0)});
local tweenTouchEnd = tweenService:Create(roblonx, TweenInfo.new(2, Enum.EasingStyle.Linear), {Color = roblonx.Color});
local tweenTouchAnchorEnd = tweenService:Create(anchor, TweenInfo.new(2, Enum.EasingStyle.Linear), {CFrame = anchor.CFrame});

script.Parent.Touched:Connect(function(part)
	if (not part:IsDescendantOf(script.Parent.Parent) and not touchingPart) then
		touchingPart = part;
		tweenTouch:Play();
		tweenTouchAnchor:Play();
	end
end);
script.Parent.TouchEnded:Connect(function(part)
	if (touchingPart == part) then
		touchingPart = nil;
		tweenTouchEnd:Play();
		tweenTouchAnchorEnd:Play();
	end
end);
	]]
	touchScript.Parent = trigger
	trigger.Parent = roblonk
end

eval.check_scene = function() end

eval.check_game = function()
	local workspace = game:GetService("Workspace")
	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local roblonk = workspace.LevelArt.SkyMeshes.RoBlonk
	wait(8) --Stall until the texture fully loads
	local initialCFrame = roblonk.Roblonx.CFrame
	local initialColor = roblonk.Roblonx.Color
	player.Character:PivotTo(roblonk.Roblonx.CFrame * CFrame.new(0, 40, 0))
	task.wait(4)
	assert(roblonk.Roblonx.Position.Y >= initialCFrame.Position.Y + 5, "Roblonk did not rise 5 studs")
	local currentColorH, currentColorS = roblonk.Roblonx.Color:ToHSV()
	currentColorH *= 360
	assert(currentColorH <= 245 and currentColorH >= 175 and currentColorS > 0, "Roblonk did not turn blue")
	task.wait(1)
	player.Character:MoveTo(workspace.SpawnLocation.Position)
	task.wait(5)
	assert(
		math.abs(roblonk.Roblonx.Position.Y - initialCFrame.Position.Y) <= 0.1,
		"Roblonk did not go back to its original position"
	)
	assert(roblonk.Roblonx.Color == initialColor, "Roblonk did not change back to its normal color")
end

return eval
