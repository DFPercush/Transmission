
--Client.heuristics_system.test_acc.get_average()
--Client.heuristics_system.test_acc.get_count()

-- TODO: Have a cooldown on changing selections, x number of events must happen to gather data first

local temp_auto_attack_sets
local events_since_last_change = {}

local events_to_count = {'melee_swing_by_player',}

local gear_change_cooldown_event_counts = {}
gear_change_cooldown_event_counts.melee_swing_by_player = 10

function increment_event_count(event_params)
	events_since_last_change[event_params.event_name] = events_since_last_change[event_params.event_name] + 1
end
for _,event_name in pairs(events_to_count) do
	events_since_last_change[event_name] = 0
	Client.register_event(event_name, increment_event_count)
end




function select_gear(temp_auto_attack_sets)
	-- Select point on accuracy axis closest to the inverse percentage of accuracy rate
	-- Agnostic to all other axis values (for now)
	local normalized_inverse_acc_percentage = (Client.heuristics_system.cur().acc:get_average() / 100.0)
	local highest_acc = 0.00001
	local accuracy_selector = 2
	for _,set in pairs(temp_auto_attack_sets) do
		local acc_value = set.apparent_utility_results[accuracy_selector] -- TODO: numbered indices for this kind of thing is kinda eeeehhh
		if (acc_value > highest_acc) then highest_acc = acc_value end
	end
	local set_with_acc_closest_to_inverse = {}
	local lowest_diff = 10
	for _,set in pairs(temp_auto_attack_sets) do
		local normalized_acc_value = set.apparent_utility_results[accuracy_selector] / highest_acc
		local diff = math.abs(normalized_acc_value - normalized_inverse_acc_percentage)
		if (diff < lowest_diff) then
			set_with_acc_closest_to_inverse = set
		end
	end
	--print("EQUIP DIS: ")
	--print(get_gear_set_string(set_with_acc_closest_to_inverse.categorized_gear_list, set_with_acc_closest_to_inverse.indices))
	--print("Trying to equip a thing")
	Client.equip_set(set_with_acc_closest_to_inverse)
end

local predicates = Client.event_system.predicates
Client.register_event('action_attack', function (...)
	--if true then return end
	--if events_since_last_change.melee_swing_by_player < gear_change_cooldown_event_counts.melee_swing_by_player then return end
	--gear_change_cooldown_event_counts.melee_swing_by_player = 0

	--if (temp_auto_attack_sets == nil) then
	--	-- NO, GOD, NO, FUCK THIS
	--	--build_auto_attack():next(function (result)
	--	--	--print(result)
	--	--	temp_auto_attack_sets = result
	--	--	select_gear(temp_auto_attack_sets)
	--	--end)
	--else
	--	select_gear(temp_auto_attack_sets)
	--end
	
end, predicates.is_player_action)
