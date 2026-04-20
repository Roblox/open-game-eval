--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "107_lasertag_grenade_weapon",
	prompt = {
		{
			{
				role = "user",
				content = [[Add a realistic grenade weapon as a third weapon option to this game.]],
				request_id = "s20250919_004",
			},
		},
	},
	place = "laser_tag.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	},
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local OldSpace = utils_he.getAllReasonableItems()

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
	local tool = Instance.new("Tool")
	local GrenadeHandler = Instance.new("Script")
	local throwAnim = Instance.new("Animation")
	local handle = Instance.new("Part")
	local explodeSound = Instance.new("Sound")
	local mesh = Instance.new("SpecialMesh")
	local mouseInfo = Instance.new("LocalScript")
	local MouseInfoRE = Instance.new("RemoteEvent")

	handle.Parent = tool
	GrenadeHandler.Parent = tool
	MouseInfoRE.Parent = tool

	mesh.Scale = Vector3.new(0.003, 0.002, 0.003)
	MouseInfoRE.Name = "MouseInfoRE"
	mesh.Name = "Mesh"
	handle.Name = "Handle"
	explodeSound.Name = "ExplodeSound"
	throwAnim.Name = "ThrowAnim"
	GrenadeHandler.Name = "GrenadeHandler"
	mouseInfo.Name = "MouseInfo"
	throwAnim.Parent = GrenadeHandler
	mesh.Parent, explodeSound.Parent = handle, handle
	handle.Size = Vector3.new(0.5, 0.5, 0.5)
	mouseInfo.Source = [[
local mouse = game.Players.LocalPlayer:GetMouse()


game:GetService("RunService").RenderStepped:Connect(function()
	
	
	script.Parent.MouseInfoRE:FireServer(mouse.Hit)
end)
	]]

	GrenadeHandler.Source = [[
local tool = script.Parent


local cooldown = 3
local coolingDown = false

local explodesIn = 3


local char


tool.Equipped:Connect(function()
	
	char = tool.Parent
end)

tool.Unequipped:Connect(function()
	
	char = nil
end)


local mouseCF

tool.MouseInfoRE.OnServerEvent:Connect(function(plr, mouseHit)
	
	mouseCF = mouseHit
end)


tool.Activated:Connect(function()
	
	if coolingDown then return end
	
	coolingDown = true
	
	
	char.Humanoid:LoadAnimation(script.ThrowAnim):Play()
	
	wait(0.1)
	
	
	local clone = tool.Handle:Clone()
	
	tool.Handle.Transparency = 1
	
	
	local bv = Instance.new("BodyVelocity")
	bv.Velocity = mouseCF.LookVector * 100
	bv.Parent = clone
	
	
	clone.Parent = workspace
	
	clone.CanCollide = true
	
	
	local explodeCoro = coroutine.wrap(function()
		
		
		wait(explodesIn)
		
		local explosion = Instance.new("Explosion")
		
		explosion.Position = clone.Position
		
		explosion.Parent = clone
		
		clone.ExplodeSound:Play()
		
		wait(1)
		clone:Destroy()
	end)
	
	explodeCoro()
	
	
	wait(0.1)
	
	bv:Destroy()
	

	wait(cooldown - 0.2)
	
	tool.Handle.Transparency = 0
	coolingDown = false
end)
	]]
	tool.Name = "Throwing Grenade"
	mouseInfo.Parent = tool
	throwAnim.AnimationId = "rbxassetid://6393681033"
	tool.Parent = game:GetService("StarterPack")
end

eval.check_scene = function()
	local newSpace = utils_he.getAllReasonableItems()
	local diff = utils_he.table_difference(OldSpace, newSpace)

	assert(diff[1], "nothing new was added")

	local keyWords = { "grenade", "lookvector", "Explosion", "particleEffect", "Velocity", "activated" }
	local maxSizeForGrenadeDemensions = Vector3.new(2, 2, 2)

	local toolAdded = false
	local scriptAdded = false
	local EventAdded = false
	local KeyWordScore = 0

	for _, item in diff do
		if item:IsA("BasePart") then
			assert(
				item.Size.X <= maxSizeForGrenadeDemensions.X
					and item.Size.Y <= maxSizeForGrenadeDemensions.Y
					and item.Size.Z <= maxSizeForGrenadeDemensions.Z,
				"Incorrect Size to be grenade"
			)
		elseif item:IsA("Tool") then
			toolAdded = true
		elseif item:IsA("LuaSourceContainer") then
			scriptAdded = true
			local source = item.Source
			for _, word in keyWords do
				if source:lower():find(word:lower()) then
					KeyWordScore += 1
				end
			end
		elseif item:IsA("RemoteEvent") then
			EventAdded = true
		end
	end

	assert(toolAdded, "Tool Was Not Added")
	assert(scriptAdded, "No Script Was Added")
	assert(EventAdded, "No remote event was added")
	assert(KeyWordScore >= 2, "Not enough keywords to make a functional and realistic grenade")
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function() end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService) end)

return eval
