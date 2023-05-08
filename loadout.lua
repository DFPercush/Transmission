
local flags = require("flags")
local slips = require("slips")

-- TODO: Resolve waiting promises from item transfers once the item is seen in inventory
Client.register_event("add_item", function() end)


local function async_transfer_to_inventory(item)
	-- TODO: if item.slip then...
	if item == nil then return Promise.reject("item (nil) not found") end
	local itemid = item.id
	local accessible = Client.item_utils.is_transferrable(item)
	local pull_item_timeout = Conf.LOADOUT_MANUAL_TRANSFER_TIMEOUT -- Give the player a few minutes to find the item manually
	if accessible then
		pull_item_timeout = 10
		Client.system.ffxi.get_item(item.storage, item.slot, item.count)
	else
		notice("Pull " .. Client.item_utils.get_item_name(item) .. " from " .. item.storage .. " slot " .. item.slot)
	end
	return Client.event_system.utils.expect("add_item", pull_item_timeout,
		function(event_object)
			return (event_object.id == itemid)
		end
	)
end

















local function get_applicable_sets(job, level)
	if GEAR_CACHE.combos[job] == nil then return end
	local level_found = 0
	for level_in_cache, level_data in pairs(GEAR_CACHE.combos[job]) do
		if level_in_cache <= level and level_in_cache > level_found then
			level_found = level_in_cache
		end
	end
	if level_found == 0 then return end
	return GEAR_CACHE.combos[job][level_found]
end

local function extract_item_ids_from_gear_set_list(gear_set_list)
	local ret = {}
	local bykeys = {}
	for _, set in pairs(gear_set_list) do
		for slot_id, slot_item in pairs(set) do
			if bykeys[slot_item.id] == nil then
				bykeys[slot_item.id] = 1
			else
				bykeys[slot_item.id] = bykeys[slot_item.id] + 1
			end
		end
	end
	for k,v in pairs(bykeys) do
		ret[#ret+1] = k
		if v > 1 then
			ret[#ret+1] = k
		end
	end
	return ret
end

local function get_equippable_by_itemid_key()
	local all_equipment = Client.item_utils.get_all_equipment()
	local ret = {}
	for _, item in pairs(all_equipment) do
		if find({"inventory", "wardrobe", "wardrobe2", "wardrobe3", "wardrobe4"}, item.storage) then
			ret[item.id] = (ret[item.id] or 0) + 1
		end
	end
end

local function filter_raw_itemids_by_not_in_equippable_storage(ids)
	local equippabe_by_key = get_equippable_by_itemid_key()
	return filter(ids,
		function(itemid)
			-- TODO: rings/earrings/weapons: one could be in wardrobe while other in storage
			return equippabe_by_key[itemid] == nil
		end
	)
end

local function dump_to_porter(itemid)
	local item_name = Client.item_utils.get_item_name({id=itemid})
	local slip_number = slips.get_slip_number_by_id(slips.get_slip_id_by_item_id(itemid))
	if not slip_number then 
		return Promise.reject("Logic error/bug: Item " .. itemid .. "(" .. item_name ..	") can not be stored at porter moogle")
	end
	print("Please store " .. item_name .. " in storage slip " .. slip_number)
	return Client.event_system.utils.expect("remove_item", Conf.LOADOUT_MANUAL_TRANSFER_TIMEOUT,
		function(event_object)
			return event_object.id == itemid
		end
	)
end

local function get_from_porter(itemid)
	local item_name = Client.item_utils.get_item_name({id=itemid})
	local slip_id = slips.get_slip_id_by_item_id(itemid)
	local slip_number = slips.get_slip_number_by_id(slip_id)
	local slip_page = slips.get_slip_page_by_item_id(itemid, slip_id)
	if not slip_number then 
		return Promise.reject("Logic error/bug: Item " .. itemid .. "(" .. item_name ..	") can not be stored at porter moogle")
	end
	print("Please get " .. item_name .. " from storage slip " .. slip_number .. " (page " .. slip_page .. ")")
	return Client.event_system.utils.expect("add_item", Conf.LOADOUT_MANUAL_TRANSFER_TIMEOUT,
		function(event_object)
			return event_object.id == itemid
		end
	)
end

local function get_free_space_table()
	local free = {}
	for bag_id, bag_name in pairs(flags.storage_ids) do
		free[bag_name] = Client.item_utils.get_free_space(bag_name)
	end
	return free
end

function loadout2(job, level) --, use_slips_boolean_default_true)
	if use_slips_boolean_default_true == nil then use_slips_boolean_default_true = true end
	local free = {}
	for bag_id, bag_name in pairs(flags.storage_ids) do
		free[bag_name] = Client.item_utils.get_free_space(bag_name)
	end
	local total_free_equippable = 
		free["inventory"]
		+ free["wardrobe"]
		+ free["wardrobe2"]
		+ free["wardrobe3"]
		+ free["wardrobe4"]
	local total_free_storage = 0
	for _, bag_name in Conf.WHERE_TO_DUMP_UNUSED_ITEMS_PRIORITY do
		total_free_storage = total_free_storage + free[bag_name]
	end
	
	local all_equipment = Client.item_utils.get_all_equipment()
	local sets = get_applicable_sets(job, level)
	if sets == nil then return end
	local sets_itemids = extract_item_ids_from_gear_set_list(sets)
	local fetch_itemids = filter_raw_itemids_by_not_in_equippable_storage(sets_itemids)

	--local need_to_store_count = 
	--Client.item_utils.filter_in_equippable_storage()
	--for i = 1,
	local least_used_order = {}
	for k,v in GEAR_CACHE.last_used do
		least_used_order[#least_used_order+1] =
		{
			itemid = k,
			timestamp = v,
		}
	end
	table.sort(least_used_order,
		function (a, b)
			return a.timestamp - b.timestamp
		end
	)
	local least_used_index = 0
	local dump_to_porter_items = {}
	local dump_to_storage_items = {}
	while #fetch_itemids > total_free_equippable do
		-- Need to store things to make space
		local continue = true
		while continue do
			least_used_index = least_used_index + 1
			local itemid = least_used_order[least_used_index].itemid
			if not find(sets_itemids, itemid) then
				-- Not in loadout, good to dump. Now where to put it...
				local slipid = slips.get_slip_id_by_item_id(itemid)
				if slipid ~= nil then
					table.insert(dump_to_porter_items, itemid)
				else
					table.insert(dump_to_storage_items, itemid)
				end
				continue = false
			end
		end
	end

	local sequence = Promise.resolve()

	-- dump to porter first
	for _,itemid in pairs(dump_to_porter_items) do
		function (captured_itemid)
			sequence = sequence:next(function()
				return dump_to_porter(captured_itemid)
			end)
		end (itemid)
	end

	sequence = sequence:next(function()
		free = get_free_space_table()
		--total_free_equippable = 
		--	free["inventory"]
		--	+ free["wardrobe"]
		--	+ free["wardrobe2"]
		--	+ free["wardrobe3"]
		--	+ free["wardrobe4"]
		if free["inventory"] > 0 then
			
		end	
	end)



end






















function loadout(job, level)
	if (not GEAR_CACHE.combos[job]) then
		if Conf.showmsg.LOADOUT_WARNING_NO_JOB_DATA then
			warning("No gear data for " .. job .. ", use //tm build " .. job)
		end
		return
	end
	
	local all_equipment = table.sort(Client.item_utils.get_all_equipment(),
		function(a, b)
			local order = {"inventory", "wardrobe", "wardrobe2", "wardrobe3", "wardrobe4", "sack", "satchel", "case", "safe", "safe2", "locker", "storage"}
			local ia = find(order, a.storage)
			local ib = find(order, b.storage)
			if (ia == nil and a.slip ~= nil) then ia = 20 + a.slip end
			if (ib == nil and b.slip ~= nil) then ib = 20 + b.slip end
			if ia == nil and ib == nil then
				return a.storage < b.storage
			elseif ia ~= nil and ib == nil then
				return false
			elseif ia == nil and ib ~= nil then
				return true
			else
				return (ia < ib)
			end
		end
	)

	local equippable_equipment = Client.item.item_utils.get_equippable_equipment()
	local gear_to_get_as_keys = {} -- list of item ids
	for use_level = level, 1, -1 do
		if GEAR_CACHE.combos[job][use_level] then
			for _,purpose_data in pairs(GEAR_CACHE.combos[job][level]) do
				for _, set in pairs(purpose_data.categorized_gear_lists) do
					for sloti = 0, 15 do
						local item = purpose_data.categorized_gear_lists[sloti]
						if item then
							-- Just flag it as present here. Counts will come later, but I want to avoid
							-- an expensive inner loop counting the same item for multiple purposes.
							gear_to_get_as_keys[item.id] = true -- tcount(all_equipment, function(v) return item.id == v.id end)
						end
					end -- for slot
				end -- for categorized sets
			end -- for purpose data
			break
		end -- if level data present
	end -- for use_level descending order
	
	local gear_to_get = {}
	for itemid,_ in pairs(gear_to_get_as_keys) do
		gear_to_get_as_keys[itemid] = tcount(all_equipment, function(v) return itemid == v.id end)
			- tcount(equippable_equipment, function(v) return itemid == v.id end)
		if gear_to_get_as_keys[itemid] > 1 then
			gear_to_get[#gear_to_get+1] = itemid
		end
		if gear_to_get_as_keys[itemid] > 0 then
			gear_to_get[#gear_to_get+1] = itemid
		end
	end

	local plan = {}  -- List of simple commands for a promise chain to execute. "Move .itemid from .src to .dest"
	local slip_plan = {}
	local free_count = {}
	for bag_id, bag_name in ipairs(flags.storage_ids) do
		free_count[bag_id] = Client.item_utils.get_free_space(bag_name)
	end
	--local free_slots = Client.item_utils.get_free_space("inventory")
	local wardrobe_free = {}
	wardrobe_free[1] = Client.item_utils.get_free_space("wardrobe")
	wardrobe_free[2] = Client.item_utils.get_free_space("wardrobe2")
	wardrobe_free[3] = Client.item_utils.get_free_space("wardrobe3")
	wardrobe_free[4] = Client.item_utils.get_free_space("wardrobe4")
	local wardrobe_free_all = sum(wardrobe_free)
	local least_used = {}
	local least_used_index = 1
	if #gear_to_get > wardrobe_free_all then
		-- Determine the priority to swap unused items back to storage.
		-- Filter for not in currently requested sets.
		least_used = filter(Client.heuristics_system.get_least_used_equipment(Client.item_utils.get_all_equipment()),
			function(v)
				return gear_to_get_as_keys[v.id] == nil
			end
		)
		--plan_index = plan_index + 1
		--plan[plan_index] = 
	end
	-- TODO: Transfer (free space) items from storage to wardrobes, then interleave transfer operations
	-- between wardrobe -> inventory -> storage, and storage -> inventory -> wardrobe
	local gear_to_get_index = 1
	while gear_to_get_index <= #gear_to_get do
		local plan_next = {}
		local free_found = false
		for wardrobe_index in 1,4 do
			local wardrobe_bag_id = flags.storage_ids["wardrobe" .. (wardrobe_index == 1 and "") or wardrobe_index]
			if wardrobe_free[wardrobe_index] > 0 then
				local item_before_moving = Client.item_utils.find_item(gear_to_get[gear_to_get_index], all_equipment)
				if not Client.item_utils.is_in_equippable_storage() then
					plan_next.itemid = item_before_moving.id
					plan_next.src = flags.storage_ids[item_before_moving.storage]
					plan_next.dest = flags.storage_ids["inventory"]
					plan[#plan+1] = plan_next
					plan_next = {}
					plan_next.itemid = item_before_moving.id
					plan_next.src = flags.storage_ids["inventory"]
					plan_next.dest = flags.storage_ids["wardrobe" .. ((wardrobe_index == 1 and "") or wardrobe_index) ]
					plan[#plan+1] = plan_next
					wardrobe_free[wardrobe_index] = wardrobe_free[wardrobe_index] - 1
				end
				free_found = true
				gear_to_get_index = gear_to_get_index + 1
			end
		end -- for wardrobe_index
		if not free_found then
			plan_next = {}
			plan_next.itemid = least_used[least_used_index].id
			plan_next.src = flags.storage_ids[least_used[least_used_index].storage]
			plan_next.dest = flags.storage_ids["inventory"]
			plan[#plan+1] = plan_next
			plan_next = {}
			plan_next.itemid = least_used[least_used_index].id
			plan_next.src = flags.storage_ids["inventory"]
			-- Put in which storage?
			for dump_conf_index,storage_name in ipairs(Conf.WHERE_TO_DUMP_UNUSED_ITEMS_PRIORITY) do
				local dump_bag_id = flags.storage_ids[storage_name]
				if storage_name == "slip" then
					-- TODO: Stage it somewhere for slip storage later
				--elseif dump_free[dump_conf_index] > 0 then
				elseif free_count[dump_bag_id] > 0 then
					--Client.system.put_item() flags.storage_ids[storage_name]
					plan_next.dest = flags.storage_ids[storage_name]
					plan[#plan+1] = plan_next
				end
			end -- for storage_name in dump priority
		end -- if not free_found
	end -- iterating gear_to_get
	

	local next_item_promise = Promise.resolve()
	for i,itemid in gear_to_get do
		local function capture_id_value(inner_itemid)
			--local item_index = find(all_equipment, itemid, function(item, itemid) return item.id == itemid end)
			return next_item_promise:next(
				function()
					local item = Client.item_utils.find_first_unequippable(itemid)
					if item then
						return async_transfer_to_inventory(item)
					end
				end
			)
		end
		next_item_promise = capture_id_value(itemid)
	end

	-- TODO: Conf.LOADOUT_DELAY_JITTER_MIN / MAX

	--local gear_to_get = filter(keys(gear_to_get_as_keys),
	--	function(v)
	--		local where = find(all_equipment, v,
	--			function(item, itemid)
	--				return item.id == itemid
	--			end
	--		)
	--		if not where then return false end
	--		--local item = 
	--	end
	--)
	local porter_items = {}
	local num_copies
	for i, itemid in ipairs(gear_to_get) do
		if tcount(all_equipment, function(v) return v.id == itemid end) > 1 then
			num_copies = 2
		else
			num_copies = 1
		end
	end
	-- TODO: Make sure to get both instances of ring, earring, or weapons

end
