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
    scenario_name = "pilot_024",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make the player bounce in the air when shooting the ground within 5 studs of the player.]],
                        request_id = "pilot_024"
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
    utils_runs.createPlayerScripts()
    
end

eval.reference = function()
	local StarterPlayer = game:GetService("StarterPlayer")
    local StarterPlayerScripts = StarterPlayer:FindFirstChild("StarterPlayerScripts")

    local bounceScript = Instance.new("LocalScript")
    bounceScript.Name = "GroundBounce"
    bounceScript.Source = [[
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        local camera = workspace.CurrentCamera

        local BOUNCE_DISTANCE = 5
        local BOUNCE_VELOCITY = 50

        local function checkBounce()
            local character = player.Character
            if not character then return end

            local hrp = character:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            local origin = camera.CFrame.Position
            local direction = camera.CFrame.LookVector * 1000

            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {character}
            params.FilterType = Enum.RaycastFilterType.Exclude

            local result = workspace:Raycast(origin, direction, params)
            if not result then return end

            local isGround = result.Normal.Y > 0.5
            local distance = (result.Position - hrp.Position).Magnitude

            if isGround and distance <= BOUNCE_DISTANCE then
                hrp.AssemblyLinearVelocity = Vector3.new(
                    hrp.AssemblyLinearVelocity.X,
                    BOUNCE_VELOCITY,
                    hrp.AssemblyLinearVelocity.Z
                )
            end
        end

        local function setupCharacter(character)
            for _, child in character:GetChildren() do
                if child:IsA("Tool") then
                    child.Activated:Connect(checkBounce)
                end
            end
            character.ChildAdded:Connect(function(child)
                if child:IsA("Tool") then
                    child.Activated:Connect(checkBounce)
                end
            end)
        end

        if player.Character then
            setupCharacter(player.Character)
        end
        player.CharacterAdded:Connect(setupCharacter)
    ]]

    bounceScript.Parent = StarterPlayerScripts
end

eval.check_scene = function()
    
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
    
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
    local Workspace = game:GetService("Workspace")
    local BOUNCE_DISTANCE = 5
    local MIN_BOUNCE_HEIGHT = 1

    local flatGroundPos = Vector3.new(-16.198, 0, 16.79)
    local rampPos = Vector3.new(-1.096, 2.131, 40.533)
    local wallPos = Vector3.new(28.669, 0, 1.393)
    local wallOrientation = CFrame.Angles(0, math.rad(-85), 0)
    local roofPos = Vector3.new(-14, 7, 16.79)

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    local camera = Workspace.CurrentCamera

    local rayParams = RaycastParams.new()
    rayParams.FilterDescendantsInstances = {character}
    rayParams.FilterType = Enum.RaycastFilterType.Exclude

    local groundCheck = Workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -50, 0), rayParams)
    local playerHeight = groundCheck and (humanoidRootPart.Position.Y - groundCheck.Position.Y) or 3

    local function getEquippedTool()
        for _, child in character:GetChildren() do
            if child:IsA("Tool") then return child end
        end
        return nil
    end

    local function isGrounded()
        local result = Workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -4, 0), rayParams)
        return result ~= nil and math.abs(humanoidRootPart.AssemblyLinearVelocity.Y) < 1
    end

    local function waitForGrounded()
        while not isGrounded() do task.wait(0.05) end
        task.wait(0.1)
    end

    local function checkForBounce()
        local maxHeight = character:GetPivot().Position.Y
        task.wait(0.1)
        while not isGrounded() do
            task.wait(0.02)
            maxHeight = math.max(maxHeight, character:GetPivot().Position.Y)
        end
        task.wait(0.1)
        return maxHeight - character:GetPivot().Position.Y
    end

    local function teleportTo(position, orientation)
        local targetCFrame = CFrame.new(position) * CFrame.new(0, playerHeight, 0)
        if orientation then
            targetCFrame = targetCFrame * orientation
        end
        humanoidRootPart.CFrame = targetCFrame
        waitForGrounded()
    end

    -- Fixed camera positioning: place camera above/behind player
    local function lookAt(target, isOffset)
        local lookTarget = target
        if isOffset then
            lookTarget = humanoidRootPart.Position + target
        end
        local camPos = humanoidRootPart.Position + Vector3.new(0, 2, 2)
        camera.CFrame = CFrame.new(camPos, lookTarget)
        task.wait(0.1)
    end

    local function activateTool()
        local tool = getEquippedTool()
        if tool then
            tool:Activate()
            task.wait(0.1)
            tool:Deactivate()
        end
    end

    local function getAllTools()
        local tools = {}
        local backpack = LocalPlayer:FindFirstChild("Backpack")
        if backpack then
            for _, item in backpack:GetChildren() do
                if item:IsA("Tool") then table.insert(tools, item) end
            end
        end
        local equipped = getEquippedTool()
        if equipped then table.insert(tools, equipped) end
        return tools
    end

    -- Wait for LocalScript to set up connections
    task.wait(2)
    local tools = getAllTools()

    -- Test 1: Bounce with all tools
    for _, tool in tools do
        humanoid:EquipTool(tool)
        task.wait(0.5)
        -- Aim at ground directly below player
        local groundY = groundCheck and groundCheck.Position.Y or (humanoidRootPart.Position.Y - 3)
        lookAt(Vector3.new(humanoidRootPart.Position.X, groundY, humanoidRootPart.Position.Z), false)
        activateTool()
        local height = checkForBounce()
        assert(height > MIN_BOUNCE_HEIGHT, "No bounce with " .. tool.Name)
        print("[PASS] Bounce with " .. tool.Name)
    end

    if tools[1] then
        humanoid:EquipTool(tools[1])
        task.wait(0.5)
    end

    -- Test 2: Ramp bounce
    teleportTo(rampPos)
    local groundY = groundCheck and groundCheck.Position.Y or (humanoidRootPart.Position.Y - 3)
    lookAt(Vector3.new(humanoidRootPart.Position.X, groundY, humanoidRootPart.Position.Z), false)
    activateTool()
    local height = checkForBounce()
    assert(height > MIN_BOUNCE_HEIGHT, "No bounce on ramp")
    print("[PASS] Ramp surface bounce")

    -- Test 3: Beyond 5 studs - no bounce
    teleportTo(flatGroundPos)
    task.wait(0.5)
    local ground = Workspace:Raycast(humanoidRootPart.Position, Vector3.new(0, -50, 0), rayParams)
    groundY = ground and ground.Position.Y or 0
    local h = BOUNCE_DISTANCE + 0.1
    local groundTarget = Vector3.new(
        humanoidRootPart.Position.X - h * math.cos(math.rad(45)),
        groundY,
        humanoidRootPart.Position.Z - h * math.sin(math.rad(45))
    )
    lookAt(groundTarget, false)
    activateTool()
    height = checkForBounce()
    assert(height < MIN_BOUNCE_HEIGHT, "Bounced beyond 5 studs")
    print("[PASS] Beyond 5 studs no bounce")

    -- Test 4: Wall - no bounce
    teleportTo(wallPos, wallOrientation)
    lookAt(wallOrientation.LookVector * 5, true)
    activateTool()
    height = checkForBounce()
    assert(height < MIN_BOUNCE_HEIGHT, "Bounced on wall")
    print("[PASS] Wall no bounce")

    -- Test 5: Roof - no bounce (non-collidable ceiling within range)
    teleportTo(flatGroundPos)
    task.wait(0.5)

    -- Create a non-collidable roof above the player within bounce range
    local roof = Instance.new("Part")
    roof.Name = "TestRoof"
    roof.Size = Vector3.new(10, 1, 10)
    roof.Position = humanoidRootPart.Position + Vector3.new(0, 3, 0)
    roof.Anchored = true
    roof.CanCollide = false
    roof.Transparency = 0.5
    roof.Parent = Workspace

    task.wait(0.1)
    lookAt(roof.Position, false)
    activateTool()
    height = checkForBounce()

	roof:Destroy()
    assert(height < MIN_BOUNCE_HEIGHT, "Bounced on roof/ceiling")
    print("[PASS] Roof no bounce")

    -- Test 6: Sky - no bounce
    lookAt(Vector3.new(0, 100, 0), true)
    activateTool()
    height = checkForBounce()
    assert(height < MIN_BOUNCE_HEIGHT, "Bounced shooting sky")
    print("[PASS] Sky no bounce")

    print("[PASS] All tests passed")
end)

return eval
