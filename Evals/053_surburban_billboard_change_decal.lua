--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
    scenario_name = "053_surburban_billboard_change_decal",
    prompt = {
                {
                    {
                        role = "user",
                        content = [[Make the billboard change image every 1 second, using the decals starting with 'ad'.]],
                        request_id = "s20250804_021"
                    }
                }
            },
    place = "surburban.rbxl"

}

local SelectionContextJson = "[]"
local TableSelectionContext = HttpService:JSONDecode(SelectionContextJson)

eval.setup = function()

    local assetIds = {16932675066, 7013881916, 3730712412}
    local workspace = game:GetService('Workspace')

    local billboard = workspace:FindFirstChild('Billboard')
    for i, assetId in ipairs(assetIds) do
        local url = 'rbxassetid://' .. assetId
        local decal = game:GetObjects(url)[1]

        if decal and decal:IsA('Decal') then
            decal.Name = 'ad' .. i
            decal.Parent = billboard
        end
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
end

eval.reference = function()
end

eval.check_scene = function()
end

eval.check_game = function()
	local ads = {}
	local billboards = {}

	local workspace = game:GetService('Workspace')
	local billboard = workspace:FindFirstChild('Billboard')

	for _, v in billboard:GetDescendants() do
		if v:IsA("Decal") then
			ads[v.Texture] = true

			if v.Name == "Decal" then
				billboards[v] = v.Texture
			end
		end
	end

	local successes = 0

	for i = 1, 10 do
		if successes >= 3 then break end

		for obj, lastTexture in billboards do
			if ads[obj.Texture] and lastTexture ~= obj.Texture then
				billboards[obj] = obj.Texture
				successes += 1
			end
		end

		task.wait(1)
	end
	assert(successes >= 3, "Ads are not cycling with ones found in the ads decals.")

	print("Success")
end

return eval
