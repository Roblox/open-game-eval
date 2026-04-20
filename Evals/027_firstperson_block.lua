--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "027_firstperson_block",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[hey can you make me a block that makes you firstperson when you touch it?]],
                        request_id = "s20250722_014"
                    }
                }
            },
    place = "baseplate.rbxl",

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
	local keyWords = {"Touched", "LockedFirstPerson", "Camera", "Position"}
	local scriptsAdded = 0
	local basePartsAdded = 0
	local touchPart:BasePart = nil

	for _, obj:any in newWorkspace do
		if obj:IsA("Script") then
			scriptsAdded += 1
		elseif obj:IsA("BasePart") then
			basePartsAdded += 1
			touchPart = obj
		end
	end

	assert(scriptsAdded >= 1, "No Scripts Added")
	assert(basePartsAdded >= 1, "Not enough parts")

	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local camera = workspace.CurrentCamera
	local head = character:WaitForChild("Head").Position
	local cameraPosition = camera.CFrame.Position
	local distance = (head - cameraPosition).Magnitude

	local isFirstPerson = false

	for i = 1, 120, 1 do
		humanoidRootPart.CFrame = touchPart.CFrame
		task.wait()
		if distance < 1 or player.CameraMode == Enum.CameraMode.LockFirstPerson then
			isFirstPerson = true
			break
		end
	end

	assert(isFirstPerson, "Player is not in first person.")

end

return eval
