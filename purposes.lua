

return {

	auto_attack = 
	{
		utility = function(gears, cur_indeces, return_vector, player_optional)
			EMPTY_TABLE = {}
			function get_slot(slot_name)
				local item = gears[slot_name][cur_indeces[TM_FLAGS.slot_index[slot_name]+1]]
				if (item == nil) then return EMPTY_TABLE end
				return item
			end
			function slot_res(slot_name)
				local item = get_slot(slot_name).id
				if (item == nil) then return EMPTY_TABLE end
				return resources.items[get_slot(slot_name).id]
			end
			local player = player_optional or get_player()
			--local main = resources.items[gear_set["Main"].id]
			local main = slot_res("Main")
			--local sub = resources.items[gear_set["Sub"].id]
			local sub = slot_res("Sub")
			--local ret = {}

			--local is_dual_wield = ((resources.items[gear_set["Main"].id].category == "Weapon") and (resources.items[gear_set["Sub"].id].category == "Weapon"))
			--local weapon_damage = forcenumber(resources.items[gear_set["Main"].id].damage) + forcenumber(resources.items[gear_set["Sub"].id].damage)
			--local weapon_delay = forcenumber(resources.items[gear_set["Main"].id].delay) + forcenumber(resources.items[gear_set["Sub"].id].delay)
			
			local is_dual_wield = ((slot_res("Main").category == "Weapon") and (slot_res("Sub").category == "Weapon"))
			local weapon_damage = forcenumber(slot_res("Main").damage) + forcenumber(slot_res("Sub").damage)
			local weapon_delay = forcenumber(slot_res("Main").delay) + forcenumber(slot_res("Sub").delay)
			
			-- Assume sets with dual wield (i.e. containing two weapons) will be passed in; handle filtering of sets based on presence of dual wield BEFORE this function is entered
			local dual_wield_level = get_dual_wield_level()
			if is_dual_wield then weapon_delay = weapon_delay * ({1, .9, .85, .75, .7, .65}[dual_wield_level+1]) end
			local natural_h2h_damage = (player.skills.hand_to_hand * 0.11) + 3
			if main.skill == 1 or (main.id == nil and sub.id == nil) then
				-- Hand to hand skill or bare handed
				--print("h2h")
				weapon_damage = forcenumber(main.damage) + natural_h2h_damage
				weapon_delay = {480, 400, 380, 360, 340, 320, 300, 280}[get_martial_arts_level(player) + 1]
			end

			-- TODO:
				-- Average number of swings
				-- delay / dps
				-- crit rate / dmg

			local total_mods = {} -- TODO: Memory allocation overhead?
			--apply_set_mods(total_mods, gear_set);
			apply_set_mods_by_index(total_mods, gears, cur_indeces)

			-- Assuming we hit, how much damage
			local att = forcenumber(total_mods.ATT)
			local str = forcenumber(total_mods.STR)
			local estimate_per_swing = str * ((str/2) + att)
			local estimate_swings = get_average_swings(gears, cur_indeces, total_mods, player)

			-- returns:
				-- [1] = attack/str
				-- [2] = accuracy
				-- [3] = haste
			-- TODO:
				--KICK_ATTACK_RATE
				--EXTRA_DUAL_WIELD_ATTACK
				--EXTRA_KICK_ATTACK
			-- TODO: There a lot more to account for in auto_attack, but we've got something for testing the algorithm
			return_vector[1] = 
				(estimate_per_swing * estimate_swings / weapon_delay) + 
				((natural_h2h_damage + forcenumber(total_mods.KICK_DMG)) * forcenumber(total_mods.KICK_ATTACK_RATE) / 100 / weapon_delay);
			return_vector[2] = forcenumber(total_mods.ACC)
			return_vector[3] = forcenumber(total_mods.HASTE_GEAR)
			return 3
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
	},

	build_tp =
	{
	},
	ws =
	{
	},
	tank =
	{
	},
	rest = 
	{
	},

	elemental =
	{
	},
	dark =
	{
	},

}