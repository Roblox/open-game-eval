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
	scenario_name = "pilot_021",
	prompt = {
		{
			{
				role = "user",
				content = [[Please make the cars of this game constantly change colors when they have an occupied driver.]],
				request_id = "pilot_021"
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

eval.setup = function()
	utils_runs.createPlayerScripts()

end

eval.reference = function()
	local script = Instance.new("Script")
	script.Name = "CarColorChanger"
	script.Source = [[
        local COLOR_CHANGE_INTERVAL = 0.5

        local function changeCarColor(car)
            -- Generate a random color
            local hue = math.random()
            local sat = math.random() * 0.4 + 0.6
            local val = math.random() * 0.4 + 0.6
            local color = Color3.fromHSV(hue, sat, val)

            -- Apply the color to Car.Body.Collision.body, because this is the vehicle's actual outer shell.
            local bodyPart = car:FindFirstChild("Body")
            local collision = bodyPart:FindFirstChild("Collision")
            local body = collision:FindFirstChild("body")
            body.Color = color
        end

        local function setupCar(car)
            -- Prevent double-setup
            if car:GetAttribute("ColorChangerSetup") then
                return
            end
            car:SetAttribute("ColorChangerSetup", true)
            
            -- In case for some reason the car has been discarded or disappeared.
            if not car or not car:IsDescendantOf(workspace) then
                return
            end
            
            -- Find the DriverSeat
            local driverSeat = car:FindFirstChild("DriverSeat", true)

            -- Use polling instead of signal connection to avoid interfering with car's internal systems
            task.spawn(function()
                while car and car:IsDescendantOf(workspace) do
                    if driverSeat.Occupant then
                        changeCarColor(car)
                    end
                    task.wait(COLOR_CHANGE_INTERVAL)
                end
            end)
        end

        -- when the car already exists
        -- there will be only one car for one player at same time, but if there are multiple players for an online game:
        for _, obj in workspace:GetDescendants() do
            if obj:IsA("Model") and obj.Name == "Car" then
                setupCar(obj)
            end
        end

	    -- once the car is added, call the setupCar function
        workspace.DescendantAdded:Connect(function(obj)
            if obj:IsA("Model") and obj.Name == "Car" then
            	-- wait for some possible loading time here
                task.wait(0.1)
                setupCar(obj)
            end
        end)
    ]]
	script.Parent = game:GetService("ServerScriptService")
end

-- Goal is to ensure that a script exists which has elements any reference
-- implementation would
eval.check_scene = function()
	local ServerScriptService = game:GetService("ServerScriptService")

	local foundColorScript = false

	for _, child in ipairs(ServerScriptService:GetChildren()) do
		if child:IsA("Script") then
			local source = child.Source
			-- I have taken a much better approach here compared to
			-- previous submissions. Instead of name, now we check for functionalities:
			-- 1. Color changing (Color, Color3, fromHSV, etc.)
			-- 2. Driver/Occupant detection (Occupant, DriverSeat, Seat)
			local hasColorLogic = string.find(source, "Color") ~= nil
			local hasOccupantLogic = string.find(source, "Occupant") ~= nil or
				string.find(source, "DriverSeat") ~= nil or
				string.find(source, "Seat") ~= nil

			if hasColorLogic and hasOccupantLogic then
				foundColorScript = true
				break
			end
		end
	end

	assert(foundColorScript, "No script found in ServerScriptService that handles car color changing when driver is present")
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()
	-- Get the player and character
	local Players = game:GetService("Players")
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
	local character = player.Character or player.CharacterAdded:Wait()
	task.wait(1)

	-- Clone a car from ReplicatedStorage
	-- at the end our purpose is to get a car and make the player sit in, so there is no need to follow the real game action(use script to make interaction with the component, and let the component generate a car, then make the player to sit in... we directly copy the totally same car from our storage.)
	local carTemplate = ReplicatedStorage:FindFirstChild("Car")
	assert(carTemplate, "Car template not found in ReplicatedStorage")


	local function spawnCar(location: CFrame, owner: Player?)
		local carTemplate = ReplicatedStorage:FindFirstChild("Car")
		local CarConstants = require(carTemplate.Scripts.Constants)
		local car = carTemplate:Clone()
		car:PivotTo(location)
		if owner then
			car:SetAttribute(CarConstants.CAR_OWNER_ATTRIBUTE, owner.UserId)
		end
		car.Parent = workspace
		return car
	end
	-- Use proper spawn instead of direct clone
	local car = spawnCar(character:GetPivot() * CFrame.new(5, 0, 0), player)

	task.wait(0.5)

	local driverSeat = car:FindFirstChild("DriverSeat", true)
	assert(driverSeat, "DriverSeat not found in car")

	-- Find the specific body part that changes color: Car.Body.Collision.body
	local bodyPart = car:FindFirstChild("Body")
	assert(bodyPart, "Body not found in car")

	local collision = bodyPart:FindFirstChild("Collision")
	assert(collision, "Collision not found in Body")

	local testPart = collision:FindFirstChild("body")
	assert(testPart, "body not found in Collision")
	assert(testPart:IsA("Part") or testPart:IsA("MeshPart"), "body is not a Part or MeshPart")

	-- Record the initial color before sitting
	local initialColor = testPart.Color

	-- Make the character sit in the DriverSeat
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	assert(humanoid, "Humanoid not found in character")

	driverSeat:Sit(humanoid)
	task.wait(0.5)

	-- Verify the character is sitting
	assert(driverSeat.Occupant == humanoid, "Failed to sit in DriverSeat")

	-- Test 1: Check that color changes after sitting (within 3 seconds)
	local colorChanged = false
	for i = 1, 30 do
		task.wait(0.1)
		if testPart.Color ~= initialColor then
			colorChanged = true
			break
		end
	end
	assert(colorChanged, "Car color did not change after driver entered")

	-- Test 2: Check that color continuously changes
	local color1 = testPart.Color
	task.wait(0.6)  
	local color2 = testPart.Color
	assert(color1 ~= color2, "Car color is not continuously changing")

	-- Test 3: Verify color continues changing over multiple intervals
	local color3 = testPart.Color
	task.wait(0.6)
	local color4 = testPart.Color
	assert(color3 ~= color4, "Car color stopped changing prematurely")

	-- Test 4: Check that color stops changing after driver exits
	humanoid.Sit = false
	task.wait(1)  

	local colorBeforeWait = testPart.Color
	task.wait(1.5)  
	local colorAfterWait = testPart.Color
	assert(colorBeforeWait == colorAfterWait, "Car color still changing after driver exited")
end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)
	-- client checks not needed here
end)

return eval
	