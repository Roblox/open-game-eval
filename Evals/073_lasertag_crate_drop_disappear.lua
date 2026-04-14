--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
    scenario_name = "073_lasertag_crate_drop_disappear",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make each crate drop an item and disappear after shooting them.]],
                        request_id = "s20250825_003"
                    }
                }
            },
    place = "laser_tag.rbxl",
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
end

eval.check_scene = function()
end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	local shootRemote = game:GetService("ReplicatedStorage").Blaster.Remotes.Shoot;
	assert(shootRemote, "Shoot remote not found");
	shootRemote.OnServerEvent:Connect(function(player, now, tool, cameraCFrame, targetHumanoid)
		print("Shoot remote event fired");
		print("Player", player);
		print("Now", now);
		print("Tool", tool);
		print("Camera CFrame", cameraCFrame);
		print("Target Humanoid", targetHumanoid);
	end)
end

assert(eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	local replicatedStorage = game:GetService("ReplicatedStorage");
	local players = game:GetService("Players");
	local player1 = players.LocalPlayer;
	local character = player1.Character or player1.CharacterAdded:Wait();
	local humanoid = character:WaitForChild("Humanoid");

	local tool = character:FindFirstChild("Blaster");
	humanoid:EquipTool(tool);

	local getCrates = game:GetService("Workspace").Level_Art.Architectural.Props:GetChildren();
	local destroyCount = 0;
	for _,target in getCrates do
		if (target:IsA("Model") and target.Name == "CrateSmall") then
			character:PivotTo(CFrame.new(target.WorldPivot.Position)*CFrame.new(0,0,-6));
			task.wait(0.5);
			local camera = game:GetService("Workspace").CurrentCamera;
			camera.CFrame = CFrame.new(player1.Character.PrimaryPart.Position, target.WorldPivot.Position-Vector3.new(0,2,0));
			task.wait(0.2);
			local now = game:GetService("Workspace"):GetServerTimeNow();
			replicatedStorage.Blaster.Remotes.Shoot:FireServer(now, tool, camera.CFrame, target);
			task.wait(0.5);
			destroyCount += 1;
			local itemCount = 0;
			for _,p in game:GetService("Workspace"):GetChildren() do
				if (p.Name == "Item") then
					itemCount += 1;
				end
			end
			assert(itemCount >= destroyCount, "Item did not spawn");
			assert(target.Parent == nil, "Crate was not destroyed");
			task.wait(0.5);
		end
	end

end)

return eval
