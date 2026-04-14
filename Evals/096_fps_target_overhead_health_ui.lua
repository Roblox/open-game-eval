--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
if LoadedCode:FindFirstChild("EvalUtils") then
	local types = require(LoadedCode.EvalUtils.types)
	local utils_runs = require(LoadedCode.EvalUtils.utils_runs)
	local utils_he = require(LoadedCode.EvalUtils.utils_he)
	local lib = require(LoadedCode.EvalUtils.lib)
else
	local types = require(game.LoadedCode.types)
end
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
	scenario_name = "096_fps_target_overhead_health_ui",
	prompt = {
		{
			{
				role = "user",
				content = [[Make the targets have an overhead UI displaying their current health.]],
				
			}
		}
	},
	place = "fps_system.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	}
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
	local targets = workspace:WaitForChild("Targets"):GetChildren();

	for _, target in targets do
		local humanoid = target:WaitForChild("Humanoid");
		local head = target:WaitForChild("Head");

		if not head:FindFirstChild("HealthDisplay") then
			local billboardGui = Instance.new("BillboardGui");
			billboardGui.Name = "HealthDisplay";
			billboardGui.Size = UDim2.new(0, 100, 0, 50);
			billboardGui.StudsOffset = Vector3.new(0, 2, 0);
			billboardGui.AlwaysOnTop = true;
			billboardGui.Parent = head;

			local textLabel = Instance.new("TextLabel");
			textLabel.Size = UDim2.new(1, 0, 1, 0);
			textLabel.BackgroundTransparency = 1;
			textLabel.Text = "Health: " .. humanoid.Health;
			textLabel.TextColor3 = Color3.fromRGB(0, 255, 255);
			textLabel.TextStrokeTransparency = 0;
			textLabel.Font = Enum.Font.Ubuntu;
			textLabel.TextSize = 20;
			textLabel.Parent = billboardGui;
		end


		if not target:FindFirstChild("HealthScript") then
			local scr = Instance.new("Script");
			scr.Source = [[
			local humanoid = script.Parent:WaitForChild("Humanoid");
			
			local textLabel = script.Parent:WaitForChild("Head"):WaitForChild("HealthDisplay"):WaitForChild("TextLabel");
			
			local signal = humanoid.HealthChanged:Connect(function()
				local humanoid = script.Parent:FindFirstChild("Humanoid");
				if not humanoid then signal:Destroy() return end;
				textLabel.Text = "Health: " .. math.max(0, humanoid.Health);
			end);
		]]
			scr.Name = "HealthScript";
			scr.Parent = target;
			scr.Enabled = true;
		end
	end
end

eval.check_scene = function()
	local MAX_STUDS_ABOVE_HEAD = 10;

	local function get_billboard_world_y(desc)
		local adornee = desc.Adornee;
		if adornee and adornee:IsA("BasePart") then
			return adornee.Position.Y + desc.StudsOffset.Y;
		elseif desc.Parent and desc.Parent:IsA("BasePart") then
			return desc.Parent.Position.Y + desc.StudsOffset.Y;
		elseif desc.Parent and desc.Parent:IsA("Model") then
			return desc.Parent:GetPivot().Position.Y + desc.StudsOffset.Y;
		end
		return nil;
	end

	local function find_overhead_billboard(target, head_y)
		for _, desc in target:GetDescendants() do
			if not desc:IsA("BillboardGui") then continue end;
			if not desc.Enabled then continue end;

			local world_y = get_billboard_world_y(desc);
			if not world_y then continue end;
			if world_y < head_y then continue end;
			if world_y > head_y + MAX_STUDS_ABOVE_HEAD then continue end;

			local label = desc:FindFirstChildWhichIsA("TextLabel", true);
			if label then
				return desc, label;
			end
		end
		return nil, nil;
	end

	local targets = workspace:WaitForChild("Targets"):GetChildren();

	for _, target in targets do
		local humanoid = target:WaitForChild("Humanoid");
		local head = target:WaitForChild("Head");

		local healthboard, label = find_overhead_billboard(target, head.Position.Y);

		assert(healthboard, "A Target dummy is missing a current health display");
		assert(label, "A Target dummy's health display is missing a TextLabel");

		assert(healthboard.Enabled, "HealthDisplay billboardgui should be Enabled");
		assert(healthboard.AlwaysOnTop, "HealthDisplay billboardgui should be always on top");
		assert(label.Visible, "Label should be visible");
		assert(label.BackgroundTransparency == 1, "The textlabel should have a transparent background");
	end
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	local MAX_STUDS_ABOVE_HEAD = 10;
	local targets = workspace:WaitForChild("Targets"):GetChildren();

	local function get_billboard_world_y(desc)
		local adornee = desc.Adornee;
		if adornee and adornee:IsA("BasePart") then
			return adornee.Position.Y + desc.StudsOffset.Y;
		elseif desc.Parent and desc.Parent:IsA("BasePart") then
			return desc.Parent.Position.Y + desc.StudsOffset.Y;
		elseif desc.Parent and desc.Parent:IsA("Model") then
			return desc.Parent:GetPivot().Position.Y + desc.StudsOffset.Y;
		end
		return nil;
	end

	local function find_overhead_label(target, head_y)
		for _, desc in target:GetDescendants() do
			if not desc:IsA("BillboardGui") then continue end;
			if not desc.Enabled then continue end;

			local world_y = get_billboard_world_y(desc);
			if not world_y then continue end;
			if world_y < head_y then continue end;
			if world_y > head_y + MAX_STUDS_ABOVE_HEAD then continue end;

			local label = desc:FindFirstChildWhichIsA("TextLabel", true);
			if label then
				return desc, label;
			end
		end
		return nil, nil;
	end

	local function text_contains_number(text, num)
		local rounded = tostring(math.floor(num + 0.5));
		return string.find(text, rounded, 1, true) ~= nil;
	end

	for _, target in targets do
		local humanoid = target:WaitForChild("Humanoid");
		local head = target:WaitForChild("Head");

		local healthboard, label = find_overhead_label(target, head.Position.Y);
		assert(label, "A Target dummy's overhead health display is missing a TextLabel");

		local previous_health = humanoid.Health;
		local prev_text = label.Text;

		humanoid:TakeDamage(20);
		task.wait(0.5);

		assert(humanoid.Health ~= previous_health, "A Target dummy's health isn't decreasing when taking damage");

		local expected_health = math.max(previous_health - 20, 0);
		assert(
			text_contains_number(label.Text, expected_health),
			"A Target dummy's health display is not updating correctly"
				.. " (expected text containing " .. tostring(expected_health)
				.. ", got: \"" .. label.Text .. "\")"
		);

		-- Overkill test: verify health display clamps to 0
		humanoid:TakeDamage(9999);
		task.wait(0.5);
		assert(
			text_contains_number(label.Text, 0),
			"A Target dummy's health display should show 0 when overkilled"
				.. " (got: \"" .. label.Text .. "\")"
		);
	end
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)

end)

return eval
