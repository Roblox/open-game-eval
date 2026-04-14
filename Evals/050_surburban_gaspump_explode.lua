--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "050_surburban_gaspump_explode",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Gas pump explode when player is in NearArea.]],
                        request_id = "s20250804_017"
                    }
                }
            },
    place = "surburban.rbxl",

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()

    local gasStation = workspace:FindFirstChild('Gas Station')
    if not gasStation then return end

    for _, obj in ipairs(gasStation:GetDescendants()) do
        if obj:IsA('Model') and obj.Name == 'GasPump' then
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA('LuaSourceContainer') then
                    child:Destroy()
                end
            end
        end
	end

	Instance.new("ForceField", game.StarterPlayer.StarterCharacterScripts)

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

	local players = game:GetService("Players")
    local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
    player:LoadCharacter()
    local character = player.Character or player.CharacterAdded:Wait()

	local gasStation = workspace:WaitForChild("Gas Station", math.huge)
	local rootPart = character:WaitForChild("HumanoidRootPart", math.huge)


	local function resetVelocity()
		for _, part in ipairs(character:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Velocity = Vector3.new()
			end
		end
	end

	for i, gasPump in ipairs(gasStation:GetChildren()) do
        print("Gas pump: "..gasPump.Name.." "..i)
		if gasPump.Name == 'GasPump' then
			local nearArea = gasPump:FindFirstChild("NearArea")
			local OriginalSpace = utils_he.getAllReasonableItems()
			local touchSuccess = false

			task.spawn(function()
				nearArea.Touched:Wait()
				touchSuccess = true
                print("Touched")
			end)

			resetVelocity()

			rootPart.CFrame = nearArea.CFrame

			while task.wait(0.1) do
				if touchSuccess then
					break
				else
					resetVelocity()
					rootPart.CFrame = nearArea.CFrame
				end
			end

			local success = false

			for i = 1, 10 do
                print(i)
				for _, item:any in utils_he.table_difference(OriginalSpace, utils_he.getAllReasonableItems()) do -- all new objects
					if item:IsA("Explosion") and (item.Position - nearArea.Position).Magnitude < 1 then
						success = true
						break
					end
				end
				if success then break end
				task.wait()
			end

			assert(success, "A gas pump did not explode.")

		end
	end
end

return eval
