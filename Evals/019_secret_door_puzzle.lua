--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "019_secret_door_puzzle",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Design a puzzle, when stepping on color tile parts in the order of red, blue, green, yellow, the secret door will open.]],
                        request_id = "s20250722_005"
                    }
                }
            },
    place = "baseplate.rbxl"

}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()

    --Insert a door with script to open
    local id = 8222709011
    local url = 'rbxassetid://' .. id
    local model = game:GetObjects(url)[1]
    model.Parent = workspace
    model.Name = 'SecretDoor'
    model:PivotTo(CFrame.new(Vector3.new(5, 5, 5)))

    -- Create parts with four colors
    local function createColoredPart(name, color, position)
        local part = Instance.new('Part')
        part.Name = name
        part.Parent = workspace
        part.Size = Vector3.new(2, 1, 2)
        part.Position = position
        part.BrickColor = BrickColor.new(color)
        part.CanCollide = true
        return part
    end
    local redPart = createColoredPart('RedPart', 'Really red', Vector3.new(20, 1, 8))
    local bluePart = createColoredPart('BluePart', 'Really blue', Vector3.new(16, 1, 8))
    local greenPart = createColoredPart('GreenPart', 'Bright green', Vector3.new(12, 1, 8))
    local yellowPart = createColoredPart('YellowPart', 'New Yeller', Vector3.new(8, 1, 8))

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
	local players = game:GetService("Players");
    local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait();
    player:LoadCharacter();
    local character = player.Character or player.CharacterAdded:Wait();
	local door = game:GetService("Workspace")["SecretDoor"].Door;
	local hingeRotOriginal = door.Doorframe.Hinge.Orientation;

	--Check correct order
	local buttonNameList = {"RedPart", "BluePart", "GreenPart", "YellowPart"};
	task.wait(0.5);
	for _,name in buttonNameList do
		local button = game:GetService("Workspace")[name];
		character:MoveTo(button.Position+Vector3.new(0,4,0));
		task.wait(0.5);
	end
	task.wait(0.1);
	assert(door.Doorframe.Hinge.Orientation ~= hingeRotOriginal, "failure");

	--Check wrong order
	buttonNameList = {"GreenPart", "BluePart", "RedPart", "YellowPart"};
	task.wait(0.5);
	for _,name in buttonNameList do
		local button = game:GetService("Workspace")[name];
		character:MoveTo(button.Position+Vector3.new(0,4,0));
		task.wait(0.5);
	end
	task.wait(0.1);
	assert(door.Doorframe.Hinge.Orientation == hingeRotOriginal, "failure");
end

return eval
