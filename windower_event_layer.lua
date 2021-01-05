local R = {}
local preds = require("windower_event_predicates")
R.event_predicates = preds
local handler_factories = {}
R.handler_factories = handler_factories
local event_name_map = {
--  Transmission     Windower      
	unload        = 'unload',
	addon_command = 'addon command',
}
R.event_name_map = event_name_map
R.registration_function = windower.register_event

-- Pass-through events
for t_name, w_name in pairs(event_name_map) do
	handler_factories[w_name] = function(fire_callback)	return function(...) fire_callback(t_name, {...}) end end
end

local function from_action(event, target_index, action)
	local ret = shallow_copy(action)
	ret.actor_id = event.actor_id
	ret.target_id = event.targets[target_index].id
	ret.category = event.category
	return ret
end
local make_event_from_action = from_action

local get_player = require('windower_player_utils').get_player

local action_resolvers_by_category = {
	--[0]  = {},
	[1]  = {},
	[2]  = {},
	[3]  = {},
	[4]  = {},
	[5]  = {},
	[6]  = {},
	[7]  = {},
	[8]  = {},
	[9]  = {},
	--[10] = {},
	[11] = {},
	[12] = {},
	[13] = {},
	[14] = {},
	--[15] = {},
	--[16] = {},
}

function handler_factories.action(fire_callback)
	return function(event)
		if (action_resolvers_by_category[event.category] == nil) then
			-- TODO: print diagnostics so we can add the category
		end
		local action_event
		for target_index, target_data in pairs(event.targets) do
			for action_index, action in pairs(target_data.actions) do
				action_event = make_event_from_action(event, target_index, action)
				for event_name, resolve_event in pairs(action_resolvers_by_category[action_event.category]) do
					--local event_name = resolve_event(action_event)
					--if ((event_name ~= nil) and (event_name ~= "")) then
					if resolve_event(action_event) == true then
						fire_callback(event_name, action_event)
					end
				end
			end
		end
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
		local category_description = known_cat[tonumber(event.category)]
		if (category_description == nil) then
			print(event.category .. " : Unknown event category")
		--else
		--	print(event.category .. " : " .. category_description)
		end
		--if true then return end
		--local digest = {event = event}
		local player = get_player()

		if event.category == 1 and event.target_count ~= 1 then
			error("Logic error, melee attack (category 1) has multiple or 0 targets.")
		end

		local event_name
		local params
		local is_melee_from_player = (event.actor_id == player.id) and (event.category == 1)

		local is_melee_attacking_player = false
		if event.category == 1 then
			for _,target in pairs(event.targets) do
				if target.id == player.id then
					is_melee_attacking_player = true
					break
				end
			end
		end

		--digest.is_melee_hit = (event.category == 1) and	(event.targets[1].actions[1].message == 1) -- or event.targets[1].actions[1].message == 1)
		--digest.is_melee_hit = false
		--digest.melee_hit_count = 0
		if event.category == 1 and event.target_count == 1 then
			for _,action in pairs(event.targets[1].actions) do
				if action.message == 1 then
					--digest.is_melee_hit = true
					--digest.melee_hit_count = digest.melee_hit_count + 1
					if is_melee_from_player then event_name = "melee_hit_by_player"
					elseif is_melee_attacking_player then event_name = "melee_hit_against_player"
					else event_name = "melee_hit"
					end
					params = from_action(event, 1, action)
					params.damage = params.param
					--print("adfgh")
					--print("Event generated: " .. event_name)
					fire_callback(event_name, params)
					event_name = ""
					if is_melee_from_player then
						fire_callback("melee_swing_by_player", params)
					else
						fire_callback("melee_swing", params)
					end
				end
			end
		end

		--digest.is_melee_miss = (event.category == 1) and (event.targets[1].actions[1].message == 15) -- and event.targets[1].message ~= 1)
		--digest.is_melee_miss = false
		--digest.melee_miss_count = 0
		if (event.category == 1) and (event.target_count == 1) then
			for _,action in pairs(event.targets[1].actions) do
				if action.message == 15 then
					--digest.is_melee_miss = true
					--digest.melee_miss_count = digest.melee_miss_count + 1
					if is_melee_from_player then event_name = "melee_miss_by_player"
					elseif is_melee_attacking_player then event_name = "melee_miss_against_player"
					else event_name = "melee_miss"
					end
					params = from_action(event, 1, action)
					--print("dfjkghsdfjig")
					--print("Event generated: " .. event_name)
					fire_callback(event_name, params)
					event_name = ""
					if is_melee_from_player then
						fire_callback("melee_swing_by_player", params)
					else
						fire_callback("melee_swing", params)
					end
				end
			end
		end
	end
end


function action_resolvers_by_category[1].melee_swing(ac)
	return preds.is_melee_swing(ac)
end

function action_resolvers_by_category[1].melee_swing_by_player(ac)
	if ac.actor_id == Client.get_player() then return true end
end

function action_resolvers_by_category[1].melee_hit(ac)
	return (ac.message == 1)
end

function action_resolvers_by_category[1].melee_miss(ac)
	return (ac.message == 15)
end


return R
