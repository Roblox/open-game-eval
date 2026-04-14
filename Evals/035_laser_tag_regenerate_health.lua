--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "035_laser_tag_regenerate_health",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Implement a health regeneration system that starts 2 seconds after taking damage and regenerates at 10 health per second.]],
                        request_id = "s20250804_002"
                    }
                }
            },
    place = "laser_tag.rbxl",
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()
    local StarterPlayer = game:GetService('StarterPlayer')
    local healthScript = StarterPlayer.StarterCharacterScripts:FindFirstChild("Health")

	-- Remove the Health script
	if healthScript then
		healthScript:Destroy()
	end

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

	local oldEvent = game:GetService("ReplicatedStorage"):FindFirstChild("DamageEvent");
	if oldEvent then
		oldEvent:Destroy();
	end

	local event = Instance.new("RemoteEvent");
	event.Name = "DamageEvent";
	event.Parent = game:GetService("ReplicatedStorage");
	local script = Instance.new("Script");
	script.RunContext = Enum.RunContext.Server
	script.Source = [[script.Parent.OnServerEvent:Connect(function(p)
	p.Character.Humanoid:TakeDamage(50);
end);]];
	script.Parent = event;
end

eval.reference = function()
end

eval.check_scene = function()
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local localPlayer = game:GetService("Players").LocalPlayer
	local character = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	game:GetService("ReplicatedStorage").DamageEvent:FireServer();
	task.wait(0.1)

	local startTime = os.clock()
	for i = 1, 14 do
		assert(character.Humanoid.Health == 50, "Health is regenerating too early.");
		task.wait(0.1);
	end

	while os.clock() - startTime < 2.1 do task.wait() end

	assert(character.Humanoid.Health == 60, "Health did not hit 60 at the expected time.");
	task.wait(1);
	assert(character.Humanoid.Health == 70, "Health did not hit 70 at the expected time.");
end)

return eval
