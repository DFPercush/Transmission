local R = {}
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
	return ret
end

local get_player = require('windower_player_utils').get_player

function handler_factories.action(fire_callback)
	return function(event)
		if true then return end
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

return R