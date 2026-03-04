--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------

local eval: BaseEval = {
	scenario_name = "020_gravity_well_bug_1",
	prompt = { "I set up the gravity well part, but when players touch it, they get slammed into the ground instead of floating up." },
	place = "baseplate.rbxl"
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local OriginalSpace = utils_he.getAllReasonableItems()

eval.setup = function()
local sphere = Instance.new("Part", workspace)
sphere.Shape = Enum.PartType.Ball
sphere.CFrame = CFrame.new(math.random(-10_000, 10_000) / 100, 5, math.random(-10_000, 10_000) / 100)
sphere.Size = Vector3.new(30, 30, 30)
sphere.CanCollide = false
sphere.Anchored = true

local newScript = Instance.new("Script", sphere)
newScript.Source = [[
local sphere = script.Parent
local Touching = false
local touchCount = 0
sphere.Touched:Connect(function(hit)
	if touchCount == 0 then
		touchCount += 1
		Touching = true
	end

	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")

	while Touching == true and touchCount == 1 do
		if humanoid then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
				bodyVelocity.Velocity = Vector3.new(0, -10, 0)
				bodyVelocity.Parent = rootPart
				task.wait(5)
				touchCount = 0
				bodyVelocity:Destroy()
			end
		end
	end

end)

sphere.TouchEnded:Connect(function(hit)
	Touching = false
	touchCount = 0
	for _,v in hit.Parent:GetDescendants() do
		if v:IsA("BodyVelocity") then
			v:Destroy()
		end

	end
end)
]]

newScript.Enabled = false
task.wait()
newScript.Enabled = true

end

eval.reference = function()
local sphere = Instance.new("Part", workspace)
sphere.Shape = Enum.PartType.Ball
sphere.CFrame = CFrame.new(math.random(-10_000, 10_000) / 100, 5, math.random(-10_000, 10_000) / 100)
sphere.Size = Vector3.new(30, 30, 30)
sphere.CanCollide = false
sphere.Anchored = true

local newScript = Instance.new("Script", sphere)
newScript.Source = [[
local sphere = script.Parent
local Touching = false
local touchCount = 0
sphere.Touched:Connect(function(hit)
	if touchCount == 0 then
		touchCount += 1
		Touching = true
	end

	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")

	while Touching == true and touchCount == 1 do
		if humanoid then
			local rootPart = character:FindFirstChild("HumanoidRootPart")
			if rootPart then
				local bodyVelocity = Instance.new("BodyVelocity")
				bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
				bodyVelocity.Velocity = Vector3.new(0, 10, 0)
				bodyVelocity.Parent = rootPart
				task.wait(5)
				touchCount = 0
				bodyVelocity:Destroy()
			end
		end
	end

end)

sphere.TouchEnded:Connect(function(hit)
	Touching = false
	touchCount = 0
	for _,v in hit.Parent:GetDescendants() do
		if v:IsA("BodyVelocity") then
			v:Destroy()
		end

	end
end)
]]

newScript.Enabled = false
task.wait()
newScript.Enabled = true
end

eval.check_scene = function() end

eval.check_game = function()
	local newWorkspace = utils_he.table_difference(OriginalSpace, utils_he.getAllReasonableItems())
	local keyWords = { "5", "bodyVelocity", "wait()", "touched", "while", "gravity" }
	local spheres = {}
	local scriptsAdded = 0
	local keysFound = 0
	local basePartsAdded = 0

	for _, obj: any in newWorkspace do
		if obj:IsA("Script") then
			scriptsAdded += 1
			local lowerSource = obj.Source:lower()

			for _, key in keyWords do
				if lowerSource:find(key) then
					keysFound += 1
				end
			end
		elseif obj:IsA("BasePart") then
			table.insert(spheres, obj)
		end
	end

	assert(scriptsAdded >= 1, "No Scripts Added")
	assert(keysFound >= 3, "No keywords found in scripts")
	assert(#spheres >= 1, "No parts found")

	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()

	local noTouchCheckPassed = false
	local bodyVelocityCheckPassed = false
	local simpleYAxisCheckPassed = false

	for _, sphere in spheres do
		if noTouchCheckPassed and bodyVelocityCheckPassed and simpleYAxisCheckPassed then
			break
		end

		local notTouchingScore = 0
		local TouchingScore = 0
		local movingUpScore = 0

		character:PivotTo(sphere.CFrame)

		local characterYAxis = character.HumanoidRootPart.CFrame.Y

		for i = 1, 100 do
			task.wait()

			local partPosition = sphere.Position
			local partSize = sphere.Size
			local characterPosition = character.HumanoidRootPart.Position

			local direction = (characterPosition - partPosition).Unit
			local distance = (characterPosition - partPosition).Magnitude
			local partSize = math.max(partSize.X, partSize.Y, partSize.Z)
			local distanceToPart = distance - partSize / 2

			local newYAxis = character.HumanoidRootPart.CFrame.Y

			if newYAxis > characterYAxis then
				characterYAxis = newYAxis
				movingUpScore += 1
				if movingUpScore >= 20 then
					simpleYAxisCheckPassed = true
				end
			end

			local touchingParts = sphere:GetTouchingParts()
			for _, touchingPart in touchingParts do
				if touchingPart:IsDescendantOf(character) then
					for _, object in character:GetDescendants() do
						if object:IsA("BodyVelocity") then
							if object.Velocity.Y > 0 then
								bodyVelocityCheckPassed = true
							end
							if object.Velocity.Y > 0 then
								TouchingScore += 1
							end
						end
					end
				else
					for _, object in character:GetDescendants() do
						if object:IsA("BodyVelocity") then
							if
								object.Velocity.Y ~= 0 and distanceToPart > 3
								or object.Velocity.Y <= 0 and distanceToPart > 3
							then
								notTouchingScore += 1
							end
						end
					end
				end
			end
		end

		if TouchingScore >= notTouchingScore then
			noTouchCheckPassed = true
		end
	end

	assert(noTouchCheckPassed, "grvity reverses when not touching.")
	assert(bodyVelocityCheckPassed or simpleYAxisCheckPassed, "As far as we can tell, the player is not going up.")
end

return eval
