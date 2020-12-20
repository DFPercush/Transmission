

return {

	auto_attack = 
	{
		utility = function(gear_set)
			local player = get_player()
			local main = resources.items[gear_set["Main"].id]
			local sub = resources.items[gear_set["Sub"].id]
			local ret = {}
			local is_dual_wield = ((resources.items[gear_set["Main"].id].category == "Weapon") and (resources.items[gear_set["Sub"].id].category == "Weapon"))
			local weapon_damage = forcenumber(resources.items[gear_set["Main"].id].damage) + forcenumber(resources.items[gear_set["Sub"].id].damage)
			local weapon_delay = forcenumber(resources.items[gear_set["Main"].id].delay) + forcenumber(resources.items[gear_set["Sub"].id].delay)
			-- Assume sets with dual wield (i.e. containing two weapons) will be passed in; handle filtering of sets based on presence of dual wield BEFORE this function is entered
			local dual_wield_level = get_dual_wield_level()
			if is_dual_wield then weapon_delay = weapon_delay * ({1, .9, .85, .75, .7, .65}[dual_wield_level+1]) end
			if main.skill == 1 then
				local natural_h2h_damage = (player.skills.hand_to_hand * 0.11) + 3
				weapon_damage = main.damage + natural_h2h_damage
				weapon_delay = {480, 400, 380, 360, 340, 320, 300, 280}[get_martial_arts_level(player) + 1]
			end

			-- TODO:
				-- Average number of swings
				-- delay / dps
				-- crit rate / dmg

			local total_mods = {}
			apply_set_mods(total_mods, gear_set);

			-- Assuming we hit, how much damage
			local att = forcenumber(total_mods.ATT)
			local str = forcenumber(total_mods.STR)
			local estimate_per_swing = str + ((str/2) + att)

			return estimate_per_swing / weapon_delay
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
			"HASTE_MAGIC",
			"HASTE_ABILITY",
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