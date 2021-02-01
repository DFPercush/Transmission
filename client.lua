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
	require('chat')
	require('logger')
	Client.get_current_target = function() return Client.system.ffxi.get_mob_by_target("t") end
	Client.get_current_battle_target = function() return Client.system.ffxi.get_mob_by_target("bt") end
	Client.equip_set = function(set)
		if (set.categorized_gear_list ~= nil) then
			set = set.dereference() -- numerical indices
		end
		local equipment_list = Client.get_all_equipment()
		for slot_id, stale_item in pairs(set) do
			-- TODO: when to skip first
			--if tcount(set, function(x) return x.id == stale_item.id end) > 1
			local item, accessible, skip_first
			if type(stale_item) == "table" and stale_item.id ~= nil then
				if (slot_id ==  1 and set[ 1].id == set[ 0].id) or
				(slot_id == 12 and set[12].id == set[11].id) or
				(slot_id == 14 and set[14].id == set[13].id)
				then
					skip_first = true
				else
					skip_first = false
				end
				item,accessible = Client.item_utils.find_item(stale_item.id, equipment_list, skip_first)
				if accessible then
					local inv_index = item.slot
					local slot = slot_id
					local bag = Client.item_utils.bag_double_map[string.lower(item.storage)]
					windower.ffxi.set_equip(inv_index, slot, bag)
				elseif (item ~= nil) then
					error(Client.item_utils.get_item_name(item) .. " is not accessible.")
				else
					error("Unknown item in set")
				end -- if/else accessible
			end -- if valid item id
		end -- for slot
	end -- fn equip_set()
elseif (ashita ~= nil) then
end

Client.heuristics_system = require("heuristics")
Client.event_system = Client.heuristics_system.event_system
Client.register_event = Client.event_system.register_event
Client.unregister_event = Client.event_system.unregister_event

local WARNING_ONCE_SEEN = {}
function warning_once(msg)
	local count = #WARNING_ONCE_SEEN
	insert_unique(WARNING_ONCE_SEEN, msg)
	if count ~= #WARNING_ONCE_SEEN then
		warning(msg)
	end
end

local ERROR_ONCE_SEEN = {}
function error_once(msg)
	local count = #ERROR_ONCE_SEEN
	insert_unique(ERROR_ONCE_SEEN, msg)
	if count ~= #ERROR_ONCE_SEEN then
		error(msg)
	end
end

local NOTICE_ONCE_SEEN = {}
function notice_once(msg)
	local count = #NOTICE_ONCE_SEEN
	insert_unique(NOTICE_ONCE_SEEN, msg)
	if count ~= #NOTICE_ONCE_SEEN then
		error(msg)
	end
end

function clear_onces()
	WARNING_ONCE_SEEN = {}
	ERROR_ONCE_SEEN = {}
	NOTICE_ONCE_SEEN = {}
end
