--!strict

local function loadDependencies(requested)
	local LoadedCode = game:FindFirstChild("LoadedCode")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local EvalUtils = LoadedCode:FindFirstChild("EvalUtils") or ReplicatedStorage:FindFirstChild("EvalUtils", true)
	if not EvalUtils then
		EvalUtils = Instance.new("Folder")
		EvalUtils.Name = "EvalUtils"
		EvalUtils.Archivable = true
		EvalUtils.Parent = LoadedCode
	end
	local modules = {}
	if requested then
		for _,request in requested do
			modules[request] = {}
		end
	else
		modules = {
			types = {},
			utils_he = {},
			utils_runs = {},
			utils_checks = {},
			lib = {}
		}
	end

	for moduleName,_ in modules do
		local instance = EvalUtils:FindFirstChild(moduleName) or LoadedCode:FindFirstChild(moduleName) or ReplicatedStorage:FindFirstChild(moduleName, true)
		if not instance then
			warn("Failed to find EvalUtils module: " .. moduleName)
		else    
			if(instance.Parent ~= EvalUtils) then
				instance = instance:Clone()
				instance.Archivable = false
				instance.Parent = EvalUtils
			end
		end
		modules[moduleName] = instance
	end

	if EvalUtils.Parent ~= LoadedCode then
		EvalUtils.Archivable = true
		EvalUtils = EvalUtils:Clone()
		EvalUtils.Parent = LoadedCode
	end
	for moduleName,module in modules do
		modules[moduleName] = require(module)
	end

	return modules
end
local dependencies = loadDependencies()
local types = dependencies.types
local utils_he = dependencies.utils_he
local utils_runs = dependencies.utils_runs
local utils_checks = dependencies.utils_checks
local lib = dependencies.lib

local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval

local eval: BaseEval = {
    scenario_name = "pilot_023",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make the targets display the damage with a UI after shooting the targets.]],
                        request_id = "pilot_023"
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

local TEST_REMOTE_EVENT_NAME = "EvalTestDamageEvent"

eval.setup = function()
    utils_runs.createPlayerScripts()

    -- Create RemoteEvent for test communication between server and client
    local testRemoteEvent = Instance.new("RemoteEvent")
    testRemoteEvent.Name = TEST_REMOTE_EVENT_NAME
    testRemoteEvent.Parent = game:GetService("ReplicatedStorage")
end

eval.reference = function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local StarterPlayer = game:GetService("StarterPlayer")
	local StarterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")

	local damageDisplayEvent = Instance.new("RemoteEvent")
	damageDisplayEvent.Name = "DamageDisplayEvent"
	damageDisplayEvent.Parent = ReplicatedStorage
    
	-- local script for client-side damage display in UI
	local damageDisplayLocalScript = Instance.new("LocalScript")
	damageDisplayLocalScript.Name = "DamageDisplayHandler"
	damageDisplayLocalScript.Source = [[
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local TweenService = game:GetService("TweenService")

	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local damageGui = Instance.new("ScreenGui")
	damageGui.Name = "DamageDisplayGui"
	damageGui.Parent = playerGui

	local damageDisplayEvent = ReplicatedStorage:WaitForChild("DamageDisplayEvent")

	-- display damage at world position function
	local function displayDamage(targetPosition, damageAmount)
		local camera = workspace.CurrentCamera
		if not camera then return end

		-- convert world pos
		local screenPosition, onScreen = camera:WorldToScreenPoint(targetPosition)
		if not onScreen then return end

		-- create damage label
		local damageLabel = Instance.new("TextLabel")
		damageLabel.Name = "DamageNumber"
		damageLabel.Size = UDim2.new(0, 100, 0, 50)
		damageLabel.Position = UDim2.new(0, screenPosition.X - 50, 0, screenPosition.Y - 25)
		damageLabel.BackgroundTransparency = 1
		damageLabel.Text = tostring(damageAmount)
		damageLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
		damageLabel.TextStrokeTransparency = 0.5
		damageLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
		damageLabel.Font = Enum.Font.GothamBold
		damageLabel.TextSize = 24
		damageLabel.TextScaled = false
		damageLabel.Parent = damageGui

		-- animate damage number (tween float up and fade out)
		local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local endPosition = UDim2.new(0, screenPosition.X - 50, 0, screenPosition.Y - 75)

		local moveTween = TweenService:Create(damageLabel, tweenInfo, {
			Position = endPosition,
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})

		moveTween:Play()
		moveTween.Completed:Connect(function()
			damageLabel:Destroy()
		end)
	end

	-- listen for damage display events from server
	damageDisplayEvent.OnClientEvent:Connect(function(targetPosition, damageAmount)
		displayDamage(targetPosition, damageAmount)
	end)
	]]

	damageDisplayLocalScript.Parent = StarterPlayerScripts

	-- server script to detect damage and fire damage events
	local damageServerScript = Instance.new("Script")
	damageServerScript.Name = "DamageDisplayServer"
	damageServerScript.Source = [[
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")

	local damageDisplayEvent = ReplicatedStorage:WaitForChild("DamageDisplayEvent")

	-- detect damage via humanoid health changes
	local function setupDamageDetection()
		for _, target in ipairs(workspace:GetDescendants()) do
			-- skip non models
			if not target:isA("Model") then continue end

			local humanoid = target:FindFirstChild("Humanoid")
			-- skip non humanoids
			if not humanoid then continue end

			local lastHealth = humanoid.Health
			humanoid.HealthChanged:Connect(function(newHealth)
				local damage = lastHealth - newHealth
				if damage > 0 then
					local targetPosition = target:GetPivot().Position
					for _, player in ipairs(Players:GetPlayers()) do
						damageDisplayEvent:FireClient(player, targetPosition, math.floor(damage))
					end
				end
				lastHealth = newHealth
			end)
		end
	end

	-- run setup
	setupDamageDetection()
	]]

	damageServerScript.Parent = ServerScriptService

end

eval.check_scene = function()    
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
    print("[ServerCheck] Initializing...")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Players = game:GetService("Players")

    local testRemoteEvent = ReplicatedStorage:FindFirstChild(TEST_REMOTE_EVENT_NAME) :: RemoteEvent
    assert(testRemoteEvent, "Test RemoteEvent not found in ReplicatedStorage")

    -- wait for player
    print("[ServerCheck] Waiting for player...")
    local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
    assert(player, "No player found")
    print("[ServerCheck] Player found:", player.Name)

    -- find targets with Humanoids
    local targets = {}
    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Model") and descendant.Name ~= player.Name then
            local humanoid = descendant:FindFirstChild("Humanoid")
            if humanoid then
                table.insert(targets, descendant)
            end
        end
    end
    print("[ServerCheck] Found", #targets, "targets with Humanoids")
    assert(#targets >= 2, "At least two targets with Humanoids should exist in workspace")

    -- set up listener for client ready signal
    local clientReadyEvent = Instance.new("BindableEvent")
    local clientReady = false
    testRemoteEvent.OnServerEvent:Connect(function(fromPlayer, message)
        if fromPlayer == player and message == "CLIENT_READY" then
            clientReady = true
            clientReadyEvent:Fire()
        end
    end)

    -- wait for client to be ready
    print("[ServerCheck] Waiting for client to be ready...")
    if not clientReady then
        clientReadyEvent.Event:Wait()
    end
    print("[ServerCheck] Client is ready, starting tests...")

    -- Test 1: deal 37 damage from server (unique number that won't match ammo counts)
    local target1 = targets[1]
    local humanoid1 = target1:FindFirstChild("Humanoid")
    humanoid1:TakeDamage(37)

    -- notify client to check for damage indicator
    testRemoteEvent:FireClient(player, "CHECK_DAMAGE", 37)

    -- wait for client confirmation
    local checkDoneEvent = Instance.new("BindableEvent")
    local checkResult = nil
    testRemoteEvent.OnServerEvent:Connect(function(fromPlayer, message, result)
        if fromPlayer == player and message == "CHECK_DONE" then
            checkResult = result
            checkDoneEvent:Fire()
        end
    end)

    checkDoneEvent.Event:Wait()
    assert(checkResult == true, "Client failed to find '37' damage indicator")
    print("[ServerCheck] Test 1 PASSED: Found '37' damage indicator")
    task.wait(1.2)

    -- Test 2: deal 43 damage from server
    local target2 = targets[2]
    local humanoid2 = target2:FindFirstChild("Humanoid")
    humanoid2:TakeDamage(43)

    -- notify client to check for damage indicator
    testRemoteEvent:FireClient(player, "CHECK_DAMAGE", 43)

    -- wait for client confirmation
    local checkDoneEvent2 = Instance.new("BindableEvent")
    local checkResult2 = nil
    testRemoteEvent.OnServerEvent:Connect(function(fromPlayer, message, result)
        if fromPlayer == player and message == "CHECK_DONE" then
            checkResult2 = result
            checkDoneEvent2:Fire()
        end
    end)

    checkDoneEvent2.Event:Wait()
    assert(checkResult2 == true, "Client failed to find '43' damage indicator")
    print("[ServerCheck] Test 2 PASSED: Found '43' damage indicator")
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
    print("[ClientCheck] Initializing...")
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui", 5)

    -- get test remote event
    local testRemoteEvent = ReplicatedStorage:WaitForChild(TEST_REMOTE_EVENT_NAME, 5) :: RemoteEvent
    assert(testRemoteEvent, "Test RemoteEvent not found in ReplicatedStorage")
    print("[ClientCheck] Test RemoteEvent found")

    -- helper function to find damage indicator containing the damage amount 
	-- using unique damage amounts to avoid false positives with ammo counts
    local function findDamageIndicator(damageString)
        -- Check PlayerGui (ScreenGui approach)
        for _, gui in ipairs(playerGui:GetDescendants()) do
            if gui:IsA("TextLabel") and gui.Text then
                local text = gui.Text
                -- check if text contains the damage number
                if string.find(text, damageString) then
                    return true
                end
            end
        end
        -- check workspace (BillboardGui approach)
        for _, gui in ipairs(workspace:GetDescendants()) do
            if gui:IsA("BillboardGui") then
                for _, child in ipairs(gui:GetDescendants()) do
                    if child:IsA("TextLabel") and child.Text then
                        local text = child.Text
                        if string.find(text, damageString) then
                            return true
                        end
                    end
                end
            end
        end
        return false
    end

    -- helper function to wait for CHECK_DAMAGE command and verify indicator
    local function waitForDamageCheckCommand()
        local command, damageAmount = testRemoteEvent.OnClientEvent:Wait()

        if command == "CHECK_DAMAGE" then
            task.wait(0.3)
            local damageString = tostring(damageAmount)
            local found = findDamageIndicator(damageString)
            testRemoteEvent:FireServer("CHECK_DONE", found)
            return found
        end

        return false
    end

    -- signal server that client is ready
    print("[ClientCheck] Signaling server that client is ready...")
    testRemoteEvent:FireServer("CLIENT_READY")

    -- Test 1: wait for server to deal 37 damage and check
    print("[ClientCheck] Waiting for Test 1 (37 damage)...")
    local result1 = waitForDamageCheckCommand()
    assert(result1, "Test 1: Failed to find damage indicator for 37 damage")
    print("[ClientCheck] Test 1 PASSED: Found '37' damage indicator")

    -- Test 2: wait for server to deal 43 damage and check
    print("[ClientCheck] Waiting for Test 2 (43 damage)...")
    local result2 = waitForDamageCheckCommand()
    assert(result2, "Test 2: Failed to find damage indicator for 43 damage")
    print("[ClientCheck] Test 2 PASSED: Found '43' damage indicator")
end)

return eval
