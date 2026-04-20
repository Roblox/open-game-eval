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
	scenario_name = "106_lasertag_weapon_balance",
	prompt = {
		{
			{
				role = "user",
				content = [[Can you change the behavior of the two weapon types in my game? I want one of them to feel more like a shotgun, easier to hit but with lower damage, and the other one to feel more like a sniper rifle, harder to hit but with higher damage.]],
				
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
	local Shotgun = StarterPack:FindFirstChild("AutoBlaster")
	local Sniper  = StarterPack:FindFirstChild("Blaster")

	----------------------------------
	-- SHOTGUN SETTINGS  (AutoBlaster)
	----------------------------------
	Shotgun:SetAttribute("raysPerShot", 5) -- Five pellets per round
	Shotgun:SetAttribute("damage", 5) -- Lower pellet damage, with a max of 25 if all hit
	Shotgun:SetAttribute("spread", 8) -- Wide spread for easy usage

	Shotgun:SetAttribute("range", 300) -- Shorter range akin to shotgun
	Shotgun:SetAttribute("rateOfFire", 300) -- Kept automatic but slowed down as to not overpower

	Shotgun:SetAttribute("recoilMin", Vector2.new(-20,-20)) -- Violent but controlled recoil
	Shotgun:SetAttribute("recoilMax", Vector2.new(20,20)) -- Symmetrically random

	Shotgun:SetAttribute("reloadTime", 1) -- Slightly quicker reload time

	-----------------------------------
	-- SNIPER RIFLE SETTINGS  (Blaster)
	-----------------------------------
	Sniper:SetAttribute("unanchoredImpulseForce", 1) -- Very little pushing; surgical
	Sniper:SetAttribute("damage", 100) -- Immense dammage
	Sniper:SetAttribute("spread", 1) -- Very precise, but still some error to balance

	Sniper:SetAttribute("range", 1023) -- Furthest range value permissible
	Sniper:SetAttribute("rateOfFire", 50) -- Very slow

	Sniper:SetAttribute("recoilMin", Vector2.new(-30,40)) -- Very difficult recoil handling
	Sniper:SetAttribute("recoilMax", Vector2.new(30,250)) -- Especially vertically

	Sniper:SetAttribute("reloadTime", 2.5) -- Much slower to reload

	Sniper:SetAttribute("magazineSize", 5) -- Less ammo in a clip
	Sniper:SetAttribute("_ammo", 5) -- Starting ammo set to match
end

eval.check_scene = function()
	-- Collect and deterministically order tools
	local tools = {}
	for _, descendant in game:GetDescendants() do
		if descendant:IsA("Tool") then
			table.insert(tools, descendant)
		end
	end
	table.sort(tools, function(a, b)
		return a.Name < b.Name
	end)

	---------------------------------------
	-- Critical Structural Checks
	---------------------------------------
	assert(#tools == 2, "Expected exactly 2 tools, found " .. tostring(#tools))

	local requiredAttributes = {
		"_ammo","fireMode","spread","unanchoredImpulseForce","rateOfFire","_reloading",
		"rayRadius","magazineSize","recoilMin","recoilMax","viewModel","reloadTime",
		"range","raysPerShot","damage"
	}

	for i = 1, #requiredAttributes do
		local key = requiredAttributes[i]
		requiredAttributes[key] = true
	end

	for i, tool in ipairs(tools) do
		local attrs = tool:GetAttributes()
		for key in pairs(requiredAttributes) do
			if type(key) == "string" and attrs[key] == nil then
				assert(false, "Missing attribute in tool " .. i .. ": " .. key)
			end
		end
	end

	---------------------------------------
	-- Compute Weapon Metrics
	---------------------------------------
	local weapons = {}
	for _, tool in ipairs(tools) do
		local weapon = {}
		weapon.tool = tool

		weapon.bulletsPerFire = tool:GetAttribute("raysPerShot")
		weapon.fireDamage = tool:GetAttribute("damage") * weapon.bulletsPerFire
		weapon.shotsPerSecond = tool:GetAttribute("rateOfFire") / 60
		weapon.recoilX = math.abs(tool:GetAttribute("recoilMin").X) + math.abs(tool:GetAttribute("recoilMax").X)
		weapon.recoilY = math.abs(tool:GetAttribute("recoilMin").Y) + math.abs(tool:GetAttribute("recoilMax").Y)
		weapon.recoilTotal = weapon.recoilX + weapon.recoilY
		weapon.reloadTime = tool:GetAttribute("reloadTime")
		weapon.magazineSize = tool:GetAttribute("magazineSize")
		weapon.range = tool:GetAttribute("range")
		weapon.spread = tool:GetAttribute("spread")
		weapon.impulse = tool:GetAttribute("unanchoredImpulseForce") * weapon.bulletsPerFire

		table.insert(weapons, weapon)
	end

	---------------------------------------
	-- Determine Shotgun vs Sniper Rifle
	---------------------------------------
	local shotgunIndex = 0

	local function scoreStat(stat, adjustment)
		shotgunIndex += math.sign(weapons[2][stat] - weapons[1][stat]) * adjustment
	end

	scoreStat("bulletsPerFire",  1)
	scoreStat("fireDamage",     -1)
	scoreStat("shotsPerSecond",  1)
	scoreStat("recoilY",        -1)
	scoreStat("recoilTotal",    -1)
	scoreStat("reloadTime",     -1)
	scoreStat("magazineSize",    1)
	scoreStat("range",          -1)
	scoreStat("spread",          1)
	scoreStat("impulse",         1)

	assert(shotgunIndex ~= 0, "Both weapons are equally Shotgun-like and Sniper-rifle-like")

	shotgunIndex = (math.sign(shotgunIndex) + 3) / 2
	local shotgun = weapons[shotgunIndex]
	local sniper = weapons[3 - shotgunIndex]

	---------------------------------------
	-- Critical Comparative Requirements
	---------------------------------------
	assert(sniper.fireDamage > shotgun.fireDamage,
		"Sniper rifle must deal more damage per shot than Shotgun")

	assert(sniper.recoilTotal > shotgun.recoilTotal,
		"Sniper rifle must have higher total recoil than Shotgun")

	assert(sniper.shotsPerSecond < shotgun.shotsPerSecond,
		"Sniper rifle must fire slower than Shotgun")

	---------------------------------------
	-- Flexible Comparative Requirements
	---------------------------------------
	assert(sniper.bulletsPerFire <= shotgun.bulletsPerFire,
		"Sniper rifle cannot fire more pellets per shot than Shotgun")

	assert(sniper.recoilY >= shotgun.recoilY,
		"Sniper rifle cannot have lower vertical recoil than Shotgun")

	assert(sniper.magazineSize <= shotgun.magazineSize,
		"Sniper rifle cannot have a larger magazine than Shotgun")

	assert(sniper.range >= shotgun.range,
		"Sniper rifle cannot have shorter range than Shotgun")

	assert(sniper.spread <= shotgun.spread,
		"Sniper rifle cannot have higher spread than Shotgun")

	assert(sniper.impulse <= shotgun.impulse,
		"Sniper rifle cannot have cannot have a higher total impulse than Shotgun")

	assert(sniper.reloadTime >= shotgun.reloadTime,
		"Sniper rifle cannot reload faster than Shotgun")

	---------------------------------------
	-- Gameplay Consistency Requirements
	---------------------------------------
	for i, tool in ipairs(tools) do
		local ammo = tool:GetAttribute("_ammo")
		local magazineSize = tool:GetAttribute("magazineSize")
		assert(ammo == magazineSize,
			"Tool " .. i .. " has mismatched _ammo (" .. tostring(ammo) ..
				") and magazineSize (" .. tostring(magazineSize) .. ")")
	end

	---------------------------------------
	-- Cosmetic Requirements
	---------------------------------------
	assert(tools[1].Name == "AutoBlaster",
		"Expected first tool to be named 'AutoBlaster', got '" .. tostring(tools[1].Name) .. "'")

	assert(tools[1]:GetAttribute("viewModel") == "AutoBlaster",
		"Expected first tool to have viewModel 'AutoBlaster', got '" ..
			tostring(tools[1]:GetAttribute("viewModel")) .. "'")

	assert(tools[2].Name == "Blaster",
		"Expected second tool to be named 'Blaster', got '" .. tostring(tools[2].Name) .. "'")

	assert(tools[2]:GetAttribute("viewModel") == "Blaster",
		"Expected second tool to have viewModel 'Blaster', got '" ..
			tostring(tools[2]:GetAttribute("viewModel")) .. "'")
end


-- eval.check_game = function()
-- end

assert(eval.runConfig, "runConfig is required")
eval.runConfig.serverCheck = function()

end

assert(eval.runConfig and eval.runConfig.clientChecks, "runConfig.clientChecks is required")
table.insert(eval.runConfig.clientChecks, function(logService)

end)

return eval

