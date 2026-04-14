--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "018_weather_machine",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Create a 'WeatherMachine' part that, when activated, cycles through sunny, rainy, and foggy conditions every 3 seconds, visually affecting the entire game world.]],
                        request_id = "s20250722_004"
                    }
                }
            },
    place = "baseplate.rbxl",

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local LastCloudDetails:{cover:number, density:number} = {cover = nil, density = nil}
local LastAtmosphereDetails:{density:number,offset:number,color:Color3} = {density = nil, offset= nil,color=nil}

local LastSkyDetails = {
	front = nil,
	back = nil,
	left = nil,
	right = nil,
	up = nil,
	down = nil
}

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

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
	local weatherMachine:PVInstance = Workspace:FindFirstChild("WeatherMachine") or Workspace:FindFirstChild("Weather Machine")
	assert(weatherMachine ~= nil, `No model or part named "Weather Machine" was found in the Workspace`)
end

eval.check_game = function()
	local finished = false

	local weatherMachine:PVInstance = Workspace:FindFirstChild("WeatherMachine", true)
	assert(weatherMachine ~= nil and weatherMachine:IsA("BasePart"), `No model or part named "Weather Machine" was found in the Workspace`)

	local player = if #Players:GetPlayers() > 0 then Players:GetPlayers()[1] else Players.PlayerAdded:Wait()
	if not player.Character then
        player:LoadCharacter()
    end
    local character = player.Character

	local function CompareAtmosphere():boolean
		local atmosphere:Atmosphere = game:GetService("Lighting").Atmosphere
		local hasDifference:boolean = false

		if (atmosphere.Density ~= LastAtmosphereDetails.density) then hasDifference = true end
		if (atmosphere.Offset ~= LastAtmosphereDetails.offset) then hasDifference = true end
		if (atmosphere.Color ~= LastAtmosphereDetails.color) then hasDifference = true end

		return hasDifference

	end

	local function CompareSky():boolean
		local hasDifference = false
		local sky = Lighting:FindFirstChildOfClass("Sky")
		if (sky.SkyboxBk ~= LastSkyDetails.back) then hasDifference = true end
		if (sky.SkyboxFt ~= LastSkyDetails.front) then hasDifference = true end
		if (sky.SkyboxLf ~= LastSkyDetails.left) then hasDifference = true end
		if (sky.SkyboxRt ~= LastSkyDetails.right) then hasDifference = true end
		if (sky.SkyboxUp ~= LastSkyDetails.up) then hasDifference = true end
		if (sky.SkyboxDn ~= LastSkyDetails.down) then hasDifference = true end

		return hasDifference

	end

	local function SetEnviromentDetails()
		-- Set Atmosphere Details
		local atmosphere:Atmosphere = game:GetService("Lighting").Atmosphere
		LastAtmosphereDetails = {
			color = atmosphere.Color,
			density = atmosphere.Density,
			offset = atmosphere.Offset
		}

		-- Set sky details
		local sky = Lighting:FindFirstChildOfClass("Sky")
			LastSkyDetails.front = sky.SkyboxFt
			LastSkyDetails.back	 = sky.SkyboxBk
			LastSkyDetails.left = sky.SkyboxLf
			LastSkyDetails.right = sky.SkyboxRt
			LastSkyDetails.up = sky.SkyboxUp
			LastSkyDetails.down = sky.SkyboxDn
	end

	local function CompareEnvironments()
		local hasDifference = false

		if (CompareSky() == true or CompareAtmosphere() == true) then hasDifference = true end

		return hasDifference
	end

	local function RunTests():number
		local successfulRuns = 0
		task.wait(1)
		for i=1,3 do
			successfulRuns = CompareEnvironments() == true and successfulRuns + 1 or successfulRuns
			SetEnviromentDetails()
			task.wait(1)
		end
		return successfulRuns
	end


	SetEnviromentDetails()

	--Activated by touch
	character:PivotTo(weatherMachine:GetPivot())

	--Activated by proximity prompt
	local proxPrompt:ProximityPrompt? = weatherMachine:FindFirstChildWhichIsA("ProximityPrompt", true)
	if proxPrompt then
		proxPrompt:InputHoldBegin()
		task.wait(proxPrompt.HoldDuration + 0.1)
		proxPrompt:InputHoldEnd()
	end

	task.delay(1,function()
		character:PivotTo(CFrame.identity + Vector3.new(0,5,0))
	end)

	local goodRuns = RunTests()
	assert(goodRuns >= 2, "Insufficent amount of valid environment changes!")
end

return eval
