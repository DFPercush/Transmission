require('client_base')


--[[
	
			add_and_filter_set_combination(test_results, purpose, 
			{
				categorized_gear_list = categorized_gear_list,
				purpose_checked_against = purpose,
				indices = test_indices,
				apparent_utility_results = purpose.apparent_utility(categorized_gear_list, test_indices, player),
			})
]]

if (windower ~= nil) then
	Client.get_current_target = function() return Client.system.ffxi.get_mob_by_target("t") end
	Client.get_current_battle_target = function() return Client.system.ffxi.get_mob_by_target("bt") end
	Client.equip_set = function(set)
		if (set.categorized_gear_list ~= nil) then
			set = set.dereference() -- numerical indices
		end
		for slot_id, item in pairs(set) do
			local inv_index = item.slot
			local slot = slot_id
			local bag = Client.item_utils.bag_double_map[string.lower(item.storage)]
			windower.ffxi.set_equip(inv_index, slot, bag)
		end
	end
elseif (ashita ~= nil) then
end

Client.heuristics_system = require("heuristics")
Client.event_system = Client.heuristics_system.event_system
Client.register_event = Client.event_system.register_event
Client.unregister_event = Client.event_system.unregister_event
