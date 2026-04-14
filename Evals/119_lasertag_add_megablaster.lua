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
	scenario_name = "119_lasertag_add_megablaster",
	prompt = {
		{
			{
				role = "user",
				content = [[Add a MegaBlaster that works in StarterPack.]],
				
			}
		}
	},
	place = "laser_tag.rbxl",
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
	local StarterPack = game:GetService("StarterPack")

	-- Find an existing blaster to use as template
	local templateBlaster = StarterPack:FindFirstChild("Blaster") or StarterPack:FindFirstChild("AutoBlaster")
	assert(templateBlaster, "No blaster found in StarterPack to use as template")

	-- Clone the template
	local megaBlaster = templateBlaster:Clone()
	megaBlaster.Name = "MegaBlaster"

	-- Make it "mega" by improving various attributes
	megaBlaster:SetAttribute("damage", 50)
	megaBlaster:SetAttribute("magazineSize", 50)
	megaBlaster:SetAttribute("_ammo", 50)
	megaBlaster:SetAttribute("rateOfFire", 600)
	megaBlaster:SetAttribute("spread", 2)
	megaBlaster:SetAttribute("range", 500)

	megaBlaster.Parent = StarterPack
end

eval.check_scene = function()
	local StarterPack = game:GetService("StarterPack")

	-- Test 1: Tool named "MegaBlaster" exists in StarterPack
	local megaBlaster = StarterPack:FindFirstChild("MegaBlaster")
	assert(megaBlaster, "MegaBlaster tool not found in StarterPack")
	assert(megaBlaster:IsA("Tool"), "MegaBlaster must be a Tool object")

	-- Test 2: Tool has required Handle part
	local handle = megaBlaster:FindFirstChild("Handle")
	assert(handle, "MegaBlaster must have a Handle part")
	assert(handle:IsA("BasePart"), "Handle must be a BasePart")

	-- Test 3: Handle is not anchored (allows equipping)
	assert(not handle.Anchored, "Handle must not be Anchored to allow proper equipping")

	-- Test 4: Tool has basic weapon attributes required by Blaster system
	local hasWeaponAttributes = false
	local attributes = megaBlaster:GetAttributes()

	-- Look for any of the key weapon attributes
	if attributes.damage or attributes.magazineSize or attributes._ammo or attributes.fireMode then
		hasWeaponAttributes = true
	end

	assert(hasWeaponAttributes, "MegaBlaster must have basic weapon attributes (damage, magazineSize, _ammo, or fireMode)")

	-- Test 5: Verify "Mega" differentiation - MegaBlaster should be enhanced compared to AutoBlaster
	local isMega = false
	local megaAttributes = megaBlaster:GetAttributes()

	-- Helper function to calculate DPS
	local function calculateDPS(attrs)
		local damage = attrs.damage
		local rateOfFire = attrs.rateOfFire
		local raysPerShot = attrs.raysPerShot
		local magazineSize = attrs.magazineSize
		local reloadTime = attrs.reloadTime

		local shotsPerSecond = rateOfFire / 60
		local damagePerShot = damage * raysPerShot

		-- For infinite ammo, just return raw DPS
		if not magazineSize or magazineSize == 0 then
			return damagePerShot * shotsPerSecond
		end

		-- For weapons with magazine, calculate sustained DPS
		local timeToEmptyMag = magazineSize / shotsPerSecond
		local totalDamagePerCycle = damagePerShot * magazineSize
		local sustainedDPS = totalDamagePerCycle / (timeToEmptyMag + reloadTime)

		return sustainedDPS
	end

	-- Compare against AutoBlaster (should be in the scene as the best Blaster)
	local comparisonBlaster = StarterPack:FindFirstChild("AutoBlaster") or StarterPack:FindFirstChild("Blaster")
	assert(comparisonBlaster, "AutoBlaster or Blaster not found in the scene.")

	local comparisonAttributes = comparisonBlaster:GetAttributes()

	-- Calculate DPS (handles both finite and infinite ammo)
	local megaDPS = calculateDPS(megaAttributes)
	local comparisonDPS = calculateDPS(comparisonAttributes)

	if megaDPS > comparisonDPS then
		isMega = true
	end

	-- Individual stat improvements
	local megaDamage = (megaAttributes.damage or 10) * (megaAttributes.raysPerShot or 1)
	local comparisonDamage = (comparisonAttributes.damage or 10) * (comparisonAttributes.raysPerShot or 1)

	if megaDamage > comparisonDamage then
		isMega = true
	end

	-- Special range
	if (megaAttributes.range or 1000) > (comparisonAttributes.range or 1000) then
		isMega = true
	end

	-- More accuracy
	if (megaAttributes.spread or 5) < (comparisonAttributes.spread or 5) then
		isMega = true
	end

	-- Magazine size comparison
	local megaMag = megaAttributes.magazineSize
	local comparisonMag = comparisonAttributes.magazineSize or 30
	if not megaMag or (megaMag and megaMag > comparisonMag) then
		isMega = true
	end

	-- Check for additional scripts
	local function hasExtraScripts(tool: Instance): boolean
		local scripts = tool:FindFirstChild("Scripts")
		local blaster = scripts:FindFirstChild("Blaster")
		for _, inst in ipairs(tool:GetDescendants()) do
			if inst:IsA("LuaSourceContainer") and inst ~= blaster then
				return true
			end
		end

		return false
	end

	-- Safely extract Blaster.Source
	local function safeGetBlasterSource(tool)
		if not tool then return "" end
		local scripts = tool:FindFirstChild("Scripts")
		if not scripts then return "" end

		local blaster = scripts:FindFirstChild("Blaster")
		if not blaster or not blaster:IsA("LuaSourceContainer") then
			return ""
		end

		return blaster.Source or ""
	end

    -- Unique mechanics (additional scripts)
	if hasExtraScripts(megaBlaster) and not hasExtraScripts(comparisonBlaster) then
		isMega = true
	end

	local megaSource = safeGetBlasterSource(megaBlaster)
	local compSource = safeGetBlasterSource(comparisonBlaster)

	-- Unique Blaster implementation (only compare if both sides actually have a source)
	if megaSource ~= "" and compSource ~= "" and megaSource ~= compSource then
		isMega = true
	end

	assert(isMega, "MegaBlaster should be noticeably enhanced compared to AutoBlaster (higher DPS, damage per shot, range, accuracy, magazine size, or unique mechanics)")

	-- Test 6: StarterPack location confirmed (redundant but explicit check)
	assert(megaBlaster.Parent == StarterPack, "MegaBlaster must be directly in StarterPack service")
end

-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function() end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService) end)

return eval