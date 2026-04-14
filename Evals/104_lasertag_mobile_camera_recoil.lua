--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)

local eval: BaseEval = {
	scenario_name = "104_lasertag_mobile_camera_recoil",
	prompt = {
		{
			{
				role = "user",
				content = [[My camera recoil is too high when the user is playing from a mobile device. Change the recoil amount based on the user's platform.]],
				request_id = "s20250919_001",
			},
		},
	},
	place = "laser_tag.rbxl",
	runConfig = {
		serverCheck = nil,
		clientChecks = {},
	},
}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)
local RepStorage = game:GetService("ReplicatedStorage")

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

	local defCamRecoilerSource = [[local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Constants = require(ReplicatedStorage.Blaster.Constants)
local lerp = require(ReplicatedStorage.Utility.lerp)

local camera = Workspace.CurrentCamera

local recoil = Vector2.new()
local zoom = 0

local function onRenderStepped(deltaTime: number)
	camera.CFrame *= CFrame.Angles(recoil.Y * deltaTime, recoil.X * deltaTime, 0)
	camera.FieldOfView = Constants.RECOIL_DEFAULT_FOV + zoom
	recoil = recoil:Lerp(Vector2.zero, math.min(deltaTime * Constants.RECOIL_STOP_SPEED, 1))
	zoom = lerp(zoom, 0, math.min(deltaTime * Constants.RECOIL_ZOOM_RETURN_SPEED, 1))
end

local CameraRecoiler = {}

function CameraRecoiler.recoil(recoilAmount: Vector2)
	zoom = 1
	recoil += recoilAmount
	warn(`Recoil distance: {(recoilAmount - Vector2.zero).Magnitude}`)
end

RunService:BindToRenderStep(Constants.RECOIL_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, onRenderStepped)

return CameraRecoiler]]

	local CameraRecoilerScript = RepStorage.Blaster.Scripts.CameraRecoiler
	if not CameraRecoilerScript then
		CameraRecoilerScript = Instance.new("ModuleScript")
		CameraRecoilerScript.Name = "CameraRecoiler"
		CameraRecoilerScript.Parent = RepStorage.Blaster.Scripts
	end
	CameraRecoilerScript.Source = defCamRecoilerSource
end

eval.reference = function()
	local newCameraRecoilerSource = [[local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UIS = game:GetService("UserInputService")


local Constants = require(ReplicatedStorage.Blaster.Constants)
local lerp = require(ReplicatedStorage.Utility.lerp)

local camera = Workspace.CurrentCamera

local recoil = Vector2.new()
local zoom = 0

local function onRenderStepped(deltaTime: number)
	camera.CFrame *= CFrame.Angles(recoil.Y * deltaTime, recoil.X * deltaTime, 0)
	camera.FieldOfView = Constants.RECOIL_DEFAULT_FOV + zoom
	recoil = recoil:Lerp(Vector2.zero, math.min(deltaTime * Constants.RECOIL_STOP_SPEED, 1))
	zoom = lerp(zoom, 0, math.min(deltaTime * Constants.RECOIL_ZOOM_RETURN_SPEED, 1))
end

local CameraRecoiler = {}

function CameraRecoiler.recoil(recoilAmount: Vector2)
	zoom = 1
	warn(UIS.PreferredInput)
	if (UIS.PreferredInput == Enum.PreferredInput.Touch) then
		recoilAmount = recoilAmount * .5
	end
	recoil += recoilAmount
	
end

RunService:BindToRenderStep(Constants.RECOIL_BIND_NAME, Enum.RenderPriority.Camera.Value + 1, onRenderStepped)

return CameraRecoiler]]
	local CameraRecoilerScript = RepStorage.Blaster.Scripts.CameraRecoiler
	if not CameraRecoilerScript then
		CameraRecoilerScript = Instance.new("ModuleScript")
		CameraRecoilerScript.Name = "CameraRecoiler"
		CameraRecoilerScript.Parent = RepStorage.Blaster.Scripts
	end
	CameraRecoilerScript.Source = newCameraRecoilerSource
end

eval.check_scene = function()
	local CameraRecoiler = RepStorage.Blaster.Scripts.CameraRecoiler
	assert(CameraRecoiler, "No Camera Recoiler module detected!")

	local recoilerSource = CameraRecoiler.Source

	local function HasPrefferedInput(source: string): boolean
		local hasPreferredInput = source:find("PreferredInput", 1, true)
		if hasPreferredInput then
			return true
		else
			return false
		end
	end

	local function HasInputCategorizer(source: string): boolean
		local hasCategorizer = source:find(".InputCategorizer)", 1, true)
		local usesCategorizer = source:find(".getLastInputCategory()", 1, true)
		if hasCategorizer and usesCategorizer then
			return true
		else
			return false
		end
	end

	local success = HasPrefferedInput(recoilerSource)
	if not success then
		success = HasInputCategorizer(recoilerSource)
	end

	assert(success, "No valid input detection in Camera Recoiler!")
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function() end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService) end)

return eval
