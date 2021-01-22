-- Here, a purpose means any action (like a spell, ability, or weapon skill),
--	or state (like auto_attack, idle/movement speed), which can be boosted by gear.

--local get_modifier_by_alias = require("modifier_aliases")
local modifiers = require("modifiers")
local r = {}

local EMPTY_TABLE = {}

--print(debug.traceback("purposes.lua loaded from"))

--[[
local function calc_total_mods(gear_list, indices)
	local r = {}
	r.by_name = function(t, alias, default_value)
		return t[Client.item_utils.get_modifier_id(alias)] or default_value or 0
	end
	Client.item_utils.apply_set_mods_by_index(r, gear_list, indices)
	return r
end
]]


-- Things like STR, DEX, atk, etc.
local function atomic_stat(alias)
	local atom = {}
	local mod_name = Client.item_utils.get_modifier_by_alias(alias)
	local mod_id = Client.item_utils.get_modifier_id(mod_name)
	if mod_id == nil then return {} end

	atom.name = mod_name
	atom.num_of_dimensions = 1
	atom.dimension_names = { mod_name }

	function atom.apparent_utility(gear_list, cur_indices, player_optional)
		local player = player_optional or Client.get_player()
		local total = Client.item_utils.calc_total_mods(gear_list, cur_indices)
		return modifiers[mod_id]
	end
	function atom.select(set_list)
		-- Cache should only be used for purposes that do not depend on dynamic/heuristic data
		set_list.select_cache = set_list.select_cache or {}
		if set_list.select_cache[mod_name] ~= nil then
			return set_list.select_cache[mod_name]
		end
		local max_value = 0
		local ret
		for _,set in pairs(set_list) do
			--local value = Client.item_utils.calc_total_mods(set.categorized_gear_list, set.indices)
			local value = set.total_mods[mod_name]
			if (value > max_value) then
				ret = set
				max_value = value
			end
		end
		set_list.select_cache[mod_name] = ret
		return ret
	end
	atom.relevant_modifiers = { mod_name }
	atom.want_negative = {}
	return atom
end

r.auto_attack = {
	
		name = "auto_attack",
		num_of_dimensions = 3, -- Could possibly make this a table that describes the dimensions, and if you want the number, just get the length of the table
		dimension_names = { "Attack", "Accuracy", "Haste"},
		apparent_utility = function(gear_list, cur_indices, player_optional)
			
			--function get_slot(slot_name)
			--	--local item = gear_list[slot_name][cur_indeces[TM_FLAGS.slot_index[slot_name]+1]]
			--	local item = gear_list[slot_name][cur_indices[Client.item_utils.flags.slot_index[slot_name]]]
			--	if (item == nil) then return EMPTY_TABLE end
			--	return item
			--end
			--function slot_res(slot_name)
			--	local item_id = get_slot(slot_name).id
			--	if (item_id == nil) then return EMPTY_TABLE end
			--	return resources.items[item_id]
			--end

			local set = Client.item_utils.create_indexed_set(gear_list, cur_indices)
			local player = player_optional or Client.get_player()
			--local main = resources.items[gear_set["Main"].id]
			local main = set.get_slot_res("Main") or {}
			--local sub = resources.items[gear_set["Sub"].id]
			local sub = set.get_slot_res("Sub") or {}
			--local ret = {}

			--local is_dual_wield = ((resources.items[gear_set["Main"].id].category == "Weapon") and (resources.items[gear_set["Sub"].id].category == "Weapon"))
			--local weapon_damage = forcenumber(resources.items[gear_set["Main"].id].damage) + forcenumber(resources.items[gear_set["Sub"].id].damage)
			--local weapon_delay = forcenumber(resources.items[gear_set["Main"].id].delay) + forcenumber(resources.items[gear_set["Sub"].id].delay)
			
			local is_dual_wield = ((main.category == "Weapon") and (sub.category == "Weapon"))
			local weapon_damage = forcenumber(main.damage) + forcenumber(sub.damage)
			local weapon_delay = forcenumber(main.delay) + forcenumber(sub.delay)
			
			-- Assume sets with dual wield (i.e. containing two weapons) will be passed in; handle filtering of sets based on presence of dual wield BEFORE this function is entered
			local dual_wield_level = Client.player_utils.get_dual_wield_level()
			if is_dual_wield then weapon_delay = weapon_delay * ({1, .9, .85, .75, .7, .65}[dual_wield_level+1]) end
			local natural_h2h_damage = (player.skills.hand_to_hand * 0.11) + 3
			if main.skill == 1 or (main.id == nil and sub.id == nil) then
				-- Hand to hand skill or bare handed
				--print("h2h")
				weapon_damage = forcenumber(main.damage) + natural_h2h_damage
				weapon_delay = {480, 400, 380, 360, 340, 320, 300, 280}[Client.player_utils.get_martial_arts_level(player) + 1]
			end

			-- TODO:
				-- Average number of swings
				-- delay / dps
				-- crit rate / dmg

			--local total_mods = Client.item_utils.calc_total_mods(gear_list, cur_indices) --{} -- TODO: Memory allocation overhead?
			--apply_set_mods(total_mods, gear_set);
			--apply_set_mods_by_index(total_mods, gear_list, cur_indices)
			--print("Total mods for combination: ")
			--print(total_mods)

			-- Assuming we hit, how much damage
			-- Remember, this is only as a comparison to other gear, not a dps calculator
			local att = set.total_mods.by_name("ATT")
			local str = set.total_mods.by_name("STR")
			local estimate_per_swing = weapon_damage + (str * ((str/2) + att))
			local estimate_swings = get_average_swings(gear_list, cur_indices, set.total_mods, player)

			-- returns:
				-- [1] = attack/str
				-- [2] = accuracy
				-- [3] = haste
			-- TODO:
				--KICK_ATTACK_RATE
				--EXTRA_DUAL_WIELD_ATTACK
				--EXTRA_KICK_ATTACK
			-- TODO: There a lot more to account for in auto_attack, but we've got something for testing the algorithm

			--print("estimate_per_swing = " .. estimate_per_swing)
			--print("estimate_swings =" .. estimate_swings)
			--print("weapon_delay = " .. weapon_delay)
			local ret = {}
			ret[1] = 
				(estimate_per_swing * estimate_swings / weapon_delay) + 
				((natural_h2h_damage + set.total_mods.by_name("KICK_DMG")) * set.total_mods.by_name("KICK_ATTACK_RATE") / 100 / weapon_delay);
			ret[2] = set.total_mods.by_name("ACC") -- TODO: peacock charm showing 0?
			ret[3] = (set.total_mods.by_name("HASTE_GEAR") + 1) / (weapon_delay) -- TODO: Delay on weapons
			return ret
		end,

		select = function(set_list)
			-- TODO: this
			--Client.heuristics_system.cur().
		end,
		
		relevant_modifiers = 
		{
			"STR",
			"DEX",
			"ATT",
			"ACC",
			"ATTP",
			"HTH",
			"DAGGER",
			"SWORD",
			"GSWORD",
			"AXE",
			"GAXE",
			"SCYTHE",
			"POLEARM",
			"KATANA",
			"GKATANA",
			"CLUB",
			"STAFF",
			"DMG",
			"DMGPHYS",
			"DMGPHYS_II",
			"UDMGPHYS",
			"CRITHITRATE",
			"CRIT_DMG_INCREASE",
			"FENCER_CRITHITRATE",
			"SMITE",
			--"HASTE_MAGIC",
			--"HASTE_ABILITY",
			"HASTE_GEAR",
			"DELAY",
			"MARTIAL_ARTS",
			"MAX_SWINGS",
			"ADDITIONAL_SWING_CHANCE",
			"DUAL_WIELD",
			"DOUBLE_ATTACK",
			"COUNTER", -- * only applies if being hit, solo?
			"KICK_ATTACK_RATE",
			"PERFECT_COUNTER_ATT", -- ^
			"TRIPLE_ATTACK",
			"DESPERATE_BLOWS", -- * conditional on last resort
			"ZANSHIN",
			"DAKEN",
			"ENSPELL",
			"ENSPELL_DMG",
			"ENSPELL_DMG_BONUS",
			"ENSPELL_CHANCE",
			"SPIKES", -- & depends on solo/taking dmg
			"SPIKES_DMG",
			"INQUARTATA",
			"MAIN_DMG_RATING",
			"SUB_DMG_RATING",
			"MAIN_DMG_RANK",
			"SUB_DMG_RANK",
			"DELAYP",
			"KICK_DMG",
			"DA_DOUBLE_DAMAGE",
			"TA_TRIPLE_DAMAGE",
			"ZANSHIN_DOUBLE_DAMAGE",
			"EXTRA_DUAL_WIELD_ATTACK",
			"EXTRA_KICK_ATTACK",
			"SAMBA_DOUBLE_DAMAGE",
			"QUAD_ATTACK",
			"ADDITIONAL_EFFECT",
			"ITEM_SPIKES_TYPE",
			"ITEM_SPIKES_DMG",
			"ITEM_SPIKES_CHANCE",
			"AFTERMATH",
			"EXTRA_DMG_CHANCE",
			"OCC_DO_EXTRA_DMG",
			"REM_OCC_DO_DOUBLE_DMG",
			"REM_OCC_DO_TRIPLE_DMG",
			"REM_OCC_DO_DOUBLE_DMG_RANGED",
			"REM_OCC_DO_TRIPLE_DMG_RANGED",
			"MYTHIC_OCC_ATT_TWICE",
			"MYTHIC_OCC_ATT_THRICE",
			"RETALIATION",
			"AMMO_SWING",
			"AMMO_SWING_TYPE",
			"AUGMENTS_AMBUSH",
		},
		want_negative = {"DELAY"}
	}

	--[[
r.build_tp =
{
	num_of_dimensions = 0,
	apparent_utility = function(gear_list, cur_indeces, player_optional) end,
	relevant_modifiers = {},
	want_negative = {}
}
r.ws =
{
}
r.tank =
{
}
r.rest = 
{
}

r.elemental =
{
}
r.dark =
{
}

]]

-- Instantiate an atomic purpose for each mod so it can be iterated for things like rebuild_gear_cache()
for k,v in pairs(modifiers) do
	if type(v) == "string" then
		r[v] = atomic_stat(v)
	end
end

return r
