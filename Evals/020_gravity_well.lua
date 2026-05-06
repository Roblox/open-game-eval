--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "020_gravity_well",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Add a 'GravityWell' part that, when touched, inverts a player's gravity for 5 seconds or until they leave its spherical influence.]],
                        request_id = "s20250722_006"
                    }
                }
            },
    place = "baseplate.rbxl"

}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local OriginalSpace = utils_he.getAllReasonableItems()

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
	local newWorkspace = utils_he.table_difference(OriginalSpace, utils_he.getAllReasonableItems())
	local keyWords = {"5", "bodyVelocity", "wait()","touched", "while", "gravity"}
	local spheres = {}
	local scriptsAdded = 0
	local keysFound = 0
	local basePartsAdded = 0

	for _, obj:any in newWorkspace do
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
							if object.Velocity.Y ~= 0 and distanceToPart > 3 or object.Velocity.Y <= 0 and distanceToPart > 3  then
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
