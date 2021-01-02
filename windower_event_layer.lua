local handler_factories = {}

-- Pass-through events
for w_name, t_name in pairs({
-- Windower           Transmission
  ['unload']        = 'unload',
  ['addon command'] = 'addon_command',
}) do
	handler_factories[w_name] = function(fire_callback) return function(event) fire_callback(t_name, event) end end
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
				end
			end
		end
	end
end

return handler_factories