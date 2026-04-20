--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval


local eval: BaseEval = {
	scenario_name = "002_emit_white_smoke",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make white smoke come out of every chimney.]],
                        request_id = "s20250617_002"
                    }
                }
            },
    place = "surburban.rbxl",

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

local GlobalTable = {
	chimneyCount = 0,
	chimneyLocations = {}
}

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

	GlobalTable.chimneyCount = 0
	GlobalTable.chimneyLocations = {}
	for _, item in ipairs(game:GetService("Workspace"):GetDescendants()) do
		if item:IsA("Model") and item.Name == "Chimney" then
			GlobalTable.chimneyCount+=1
			table.insert(GlobalTable.chimneyLocations, item)
		end
	end
end

eval.reference = function()
end

eval.check_scene = function()
	assert(#GlobalTable.chimneyLocations>0, "No chimneys were found.")

	for _, smoke in ipairs(game:GetService("Workspace"):GetDescendants()) do
		if (smoke:IsA("Smoke") or smoke:IsA("ParticleEmitter")) and (smoke.Parent:IsA("BasePart") or smoke.Parent:IsA("Attachment")) then -- smoke lives in either parts or attachemnets
			for i, chimney in ipairs(GlobalTable.chimneyLocations) do
				local chimneyPivot = chimney:GetPivot()
				local chimneySize = chimney:GetExtentsSize()
				local chimneyTop = chimneyPivot.Position + Vector3.new(0, chimneySize.Y/2, 0)
				local isWhite = false

				if typeof(smoke.Color) == "ColorSequence" then
					for _, keypoint in pairs(smoke.Color.Keypoints) do
						if keypoint.Value.R >= (240/255) and keypoint.Value.G >= (240/255) and keypoint.Value.B >= (240/255) then
							isWhite = true
							break
						end
					end
				else
					isWhite = smoke.Color.R >= (240/255) and smoke.Color.G >= (240/255) and smoke.Color.B >= (240/255) -- all should be above 240 for white, leaves good wiggle room
				end

				local smokePos = smoke.Parent.Position
				if (smokePos - chimneyTop).Magnitude < 5 and isWhite then
					table.remove(GlobalTable.chimneyLocations, i)
					break
				end
			end
		end
	end

	for _, v in ipairs(GlobalTable.chimneyLocations) do print(v) end
	assert(#GlobalTable.chimneyLocations<=0, "A chimney was found that did not have white smoke!")
end

eval.check_game = function()
end

return eval
