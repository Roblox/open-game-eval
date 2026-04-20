--!strict

---------------------------------------------------------------------
-- ROBUST DEPENDENCY LOADER (Solves for OpenEval and Assitant Plugin)
---------------------------------------------------------------------
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
    scenario_name = "086_racing_car_jump",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make it so that when a player is driving a car and jumps, the car jumps]],
                        
                    }
                }
            },
    place = "racing.rbxl",
    runConfig = {
        serverCheck = nil,
        clientChecks = {},
    }
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

---------------------------------------------------------------------
-- SETUP – Rebinding keys that could interefere with the prompt
---------------------------------------------------------------------
eval.setup = function()
	-- Rebinding code
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local carTemplate = ReplicatedStorage:WaitForChild("Car")
	local inputs = carTemplate:WaitForChild("Inputs")

	-- Rebind handbrake off Space so it doesn't conflict with jump
	inputs:SetAttribute("keyboardHandBrakeKeyCode", Enum.KeyCode.B)
	inputs:SetAttribute("gamepadNitroKeyCode", Enum.KeyCode.ButtonY)

	-- Load PlayerModule so VirtualInputManager key events are processed
	utils_runs.createPlayerScripts()

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

---------------------------------------------------------------------
-- REFERENCE SOLUTION
---------------------------------------------------------------------
eval.reference = function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")

	-- Create RemoteEvent for jump communication
	local carJumpEvent = Instance.new("RemoteEvent")
	carJumpEvent.Name = "CarJumpEvent"
	carJumpEvent.Parent = ReplicatedStorage

	-- Server Script to handle car jumping
	local jumpServerScript = Instance.new("Script")
	jumpServerScript.Name = "CarJumpServer"
	jumpServerScript.Source = [[
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local carJumpEvent = ReplicatedStorage:WaitForChild("CarJumpEvent")

local JUMP_COOLDOWN = 1
local lastJumpTime = {}

carJumpEvent.OnServerEvent:Connect(function(player)
	local currentTime = tick()
	
	if lastJumpTime[player] and (currentTime - lastJumpTime[player]) < JUMP_COOLDOWN then
		return
	end
	
	local character = player.Character
	if not character then return end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
	local seat = humanoid.SeatPart
	if not seat or not seat:IsA("VehicleSeat") then return end

	local car = seat.Parent
	if not car then return end
	
	local chassis = car:FindFirstChild("Chassis")
	if not chassis then return end
	
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(0, math.huge, 0)
	bodyVelocity.Velocity = Vector3.new(0, 60, 0)
	bodyVelocity.Parent = chassis
	
	lastJumpTime[player] = currentTime
	
	task.delay(0.2, function()
		if bodyVelocity and bodyVelocity.Parent then
			bodyVelocity:Destroy()
		end
	end)
end)
]]
	jumpServerScript.Parent = ServerScriptService

	-- Client Script to detect jump input while driving using JumpRequest
	local StarterPlayerScripts = game:GetService("StarterPlayer"):WaitForChild("StarterPlayerScripts")

	local jumpClientScript = Instance.new("LocalScript")
	jumpClientScript.Name = "CarJumpClient"
	jumpClientScript.Source = [[
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local carJumpEvent = ReplicatedStorage:WaitForChild("CarJumpEvent")

local function isPlayerDriving()
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	local seat = humanoid.SeatPart
	if seat and seat:IsA("VehicleSeat") then
		return true
	end
	
	return false
end

UserInputService.JumpRequest:Connect(function()
	if true then
		carJumpEvent:FireServer()
	end
end)
]]
	jumpClientScript.Parent = StarterPlayerScripts
end

---------------------------------------------------------------------
-- CHECK SCENE – Empty, unneceessary for this prompt
---------------------------------------------------------------------
eval.check_scene = function()
end

---------------------------------------------------------------------
-- SERVER CHECKS – Used To Spawn A Car For Client Testing
---------------------------------------------------------------------
eval.runConfig.serverCheck = function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Workspace = game:GetService("Workspace")

	local carTemplate = ReplicatedStorage:WaitForChild("Car", 10)
	-- Server Check 1: Car template integrity
	assert(carTemplate, "Car template not found in ReplicatedStorage")

	local car = carTemplate:Clone()
	car.Name = "Car"
	car.Parent = Workspace

	local spawn = Workspace:WaitForChild("SpawnLocation", 10)

	-- Server Check 2: Spawn location integrity
	assert(spawn, "SpawnLocation not found")

	car:PivotTo(spawn:GetPivot() * CFrame.new(0, 10, -10))
end

---------------------------------------------------------------------
-- CLIENT CHECKS – Car Jump Functionality Testing
---------------------------------------------------------------------
table.insert(eval.runConfig.clientChecks, function()
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local car = Workspace:WaitForChild("Car", 10)
	-- Client Check 1: Car integrity
	assert(car, "Car not found in Workspace")

	local chassis = car:WaitForChild("Chassis", 10)
	-- Client Check 2: Chassis integrity
	assert(chassis, "Chassis not found in Car")

	local seat = car:WaitForChild("DriverSeat", 10)
	-- Client Check 3: DriverSeat integrity
	assert(seat, "DriverSeat not found in Car")

	-- Stabilize character on open-eval
	task.wait(3)

	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", 10)

	-- Clone PlayerModule into PlayerScripts so virtual key events work
	utils_runs.loadPlayerScripts()

	seat:Sit(humanoid)

	local t1 = os.clock()
	while humanoid.SeatPart == nil and os.clock() - t1 < 10 do
		task.wait(0.05)
	end

	-- Client Check 4: Humanoid seated
	assert(humanoid.SeatPart, "Player not seated on client")

	local phase = 0

	-- Simulate Space keypress to trigger jump
	utils_runs.sendKeyEvent(true, Enum.KeyCode.Space)
	task.wait(0.05)
	utils_runs.sendKeyEvent(false, Enum.KeyCode.Space)

	-- Monitor car's vertical velocity to confirm jump
	local startTime = os.time()
	while os.time() - startTime < 10 do 
		task.wait(0.2)
		local velocity = chassis.AssemblyLinearVelocity.Y
		if (phase == 0) and (velocity > 10) then
			phase = 1
		elseif (phase == 1) and (velocity < 0) then
			phase = 2
		elseif (phase == 2) and (math.abs(velocity) < 0.1) then
			phase = 3
		elseif (phase == 3) and (math.abs(velocity) < 0.1) then
			phase = 4
			break
		end
	end

	-- Client Check 5: Jump verification
	assert(phase == 4, "Car did not complete a jump, only reaching phase " .. tostring(phase) .. "/4")

	-- Client Check 6: Humanoid still seated after jump
	assert(seat.Occupant == humanoid, "Humanoid is no longer occupying the DriverSeat after jump")

end)

return eval
