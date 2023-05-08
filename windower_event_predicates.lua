local r = {}

function r.is_player_action(event)
	return (windower.ffxi.get_player().id == event.actor_id)
end

function r.is_melee_swing(ac)
	return (ac.category == 1)
end

function r.is_melee_hit(ac)
	return (r.is_melee_swing(ac) and ac.message == 1)
end
function r.is_melee_miss(ac)
	return (r.is_melee_swing(ac) and ac.message == 15)
end


return r

--[[
	
		local known_cat = {
			[0]  = "none", -- ????
			[1]  = "melee_attack",
			[2]  = "ranged_finish",
			[3]  = "weapon_finish",
			[4]  = "spell_finish", -- occurs when someone gets up from a raise as well
			[5]  = "item_finish",
			[6]  = "job_ability_finish", -- Provoke, composure
			[7]  = "ability_ready", -- mob skill, weapon skill
			[8]  = "magic_casting_start",
			[9]  = "item_use_start",
			-- 10: Job ability start, for some reason not firing on Topaz...?
			[10] = "job_ability_start",
			[11] = "mob_ability_use", -- Happens when automaton uses ranged atack too
			[12] = "ranged_start",
			[13] = "pet_ability_use",
			[14] = "dance", -- Dance...?
			-- 15: quarry?
			-- 16: sprint?
		}
]]