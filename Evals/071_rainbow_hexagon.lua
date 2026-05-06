--!strict

local LoadedCode = game:FindFirstChild("LoadedCode")
assert(LoadedCode, "Failed to find LoadedCode")

local types = require(LoadedCode.EvalUtils.types)
local HttpService = game:GetService("HttpService")
type BaseEval = types.BaseEval
local utils_he = require(LoadedCode.EvalUtils.utils_he)


local eval: BaseEval = {
	prompt = {
		scenario_name = "071_rainbow_hexagon",
		{
			{
				role = "user",
				content = [[Make 6 parts in a hexagon in the colors of a rainbox, only the red part should kill the player when they touch it]],
				request_id = "s20250709_001"
			}
		}
	},
	place = "platformer.rbxl"

}

local selection_context_json = "[]"
local table_selection_context = HttpService:JSONDecode(selection_context_json)

local OriginalSnapshot = game.Workspace:GetDescendants()

eval.setup = function()
	local selection_service = game:GetService("Selection")
	local selected_instances = {}
	for _, selection in ipairs(table_selection_context) do
		for _, instance in ipairs(game:GetDescendants()) do
			if instance.Name == selection.instanceName and instance:IsA(selection.className) then
				selected_instances[#selected_instances + 1] = instance
				break
			end
		end
	end
	selection_service:Set(selected_instances)
end

eval.reference = function()
end

eval.check_scene = function()
end

eval.check_game = function()
	-- Existence check
	local parts = {}

	for _, part in ipairs(utils_he.table_difference(OriginalSnapshot, game.Workspace:GetDescendants())) do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	assert(#parts == 6, "Exactly six parts were not created.")

	-- Color check

	local expectedHues = {
		0,
		30,
		60,
		120,
		230,
		270
	}

	local hueRegistry = {} -- Lua is kinda painful about removing table elements while in a pairs loop, so this is just safer
	local killPart = nil

	for _, entry in ipairs(expectedHues) do
		hueRegistry[entry] = 0
	end

	for _, part in ipairs(parts) do
		local h, s, _ = part.Color:ToHSV()

		h *= 360
		s *= 100

		assert(s >= 10, "Saturation on one of the parts is too low, it probably looks white because of it.")

		local hueFound = false

		for i, hue in pairs(expectedHues) do
			local diff = math.abs(h - hue)
			if diff > 180 then
				diff = 360 - diff -- circular
			end

			local diffRange = i > 2 and 30 or 15 -- because orange is in a spot within the color wheel, it makes this akward for a few colors

			if diff <= diffRange then
				hueFound = true
				hueRegistry[hue] += 1
				if hue == 0 then
					killPart = part
				end

				break
			end
		end
		assert(hueFound, "A part was added which didn't have a rainbow color.")
	end

	-- Checking if "killPart" is set is redundant so I'm not writing an assert for that.

	for _, count in pairs(hueRegistry) do
		assert(count > 0, "A color in the rainbow was not used. Expecting red, orange, yellow, green, blue, purple.")
		assert(count == 1, "Several parts were made for a specific rainbow color. We expect only just one.")
	end

	local players = game:GetService("Players")
	local player = #players:GetPlayers() > 0 and players:GetPlayers()[1] or players.PlayerAdded:Wait()
	player:LoadCharacter()
	local character = player.Character or player.CharacterAdded:Wait()
	local h = character:WaitForChild("Humanoid", 60)

	assert(h and h.Health > 0, "Need an alive player for the test.")

	for i = 1, 10 do
		-- Touched event is kinda unresponsive sometimes
		-- So we're going to be a little aggressive with this check
		h.Parent:PivotTo(killPart.CFrame)
		task.wait()

		if h.Health <= 0 then
			break
		end
	end

	assert(h.Health <= 0, "Player didn't die when they touched the part.")

	print("Success")
end

return eval
