local restricted_slots = require("restricted_slots")
local Promise = require("deferred")




-- FILTER LOGIC START!! ------------------------------------------------------------------





local function filter_relevant(equipment_list, purpose_name)
	local ret = {}
	local has = false
	local relevant_stats
	local purpose = PURPOSES[purpose_name]
	if purpose == nil then
		if Client.item_utils.modifiers[Client.item_utils.get_modifier_by_alias(purpose_name)] ~= nil then
			-- Allow a raw modifier name
			relevant_stats = { purpose_name }
		end
	else
		relevant_stats = PURPOSES[purpose_name].relevant_modifiers
	end
	if tcount(relevant_stats) == 0 then
		warn("Unknown stat: " .. purpose_name)
		return equipment_list
	end

	local quantity_limits = {}
	for _, n in pairs({0,11,12,13,14}) do quantity_limits[n] = 2 end
	for _, n in pairs({1,2,3,4,5,6,7,8,9,10,15}) do quantity_limits[n] = 1 end
	
	local good_item = false
	for _, item in pairs(equipment_list) do
		has = false
		for _, mod_text in pairs(relevant_stats) do
			--Schema: Client.item_utils.item_mods[id][modIndex] = value
			--local mod_id = modifiers[mod_text]
			local mod_id = Client.item_utils.modifiers[Client.item_utils.get_modifier_by_alias(mod_text)]
			if Client.item_utils.item_mods[item.id] ~= nil
			 and Client.item_utils.item_mods[item.id][mod_id] ~= nil
			 and Client.item_utils.item_mods[item.id][mod_id] ~= 0
			 then
				good_item = true
				-- is it actually a bonus, or a detriment?
				-- TODO: Test - It might have -DEX and +STR, think it'll still pass
				if (Client.item_utils.item_mods[item.id][mod_id] > 0) or
				 ((purpose.want_negative ~= nil) and (purpose.want_negative[mod_text])) then
					-- Prevent duplicates like multiple stacks of ammo, randomly dropped armor etc
					local num_this_item = 0
					for iRet = 1, #ret do
						if ret[iRet].id == item.id then num_this_item = num_this_item + 1 end
					end
					if num_this_item < quantity_limits[Client.item_utils.get_equipment_slot_id_of_item(item)] then
						local nextIndex = #ret+1
						ret[nextIndex] = shallow_copy(item)
						has = true
					end
					break
				end
			end
		end
	end
	-- We now have a list of all equipment that has anything to do with purpose.
	return ret
end





local function get_relevant_gear(purpose_name)
	return filter_relevant(Client.item_utils.get_equippable_equipment(), purpose_name)
end





local function populate_gear_list_numerics(gear_list)
	gear_list.count = {}
	for _,slot in pairs(resources.slots) do
		gear_list[slot.id] = gear_list[slot.en]
		gear_list.count[slot.id] = tcount(gear_list[slot.en])
	end
	return gear_list
end





local function categorize_gear_by_slot(gear_list)
	local ret = {}
	local gear_list_copy = shallow_copy(gear_list)
	for _, slot in pairs(res.slots) do
		ret[slot.en] = {}
		for equipment_item_index, equipment_item in pairs(gear_list_copy) do
			--print(res.items[equipment_item.id].slots)
			--if testbit(res.items[equipment_item.id].slots, 2^slot.id) then
			local equippable_in_this_slot = res.items[equipment_item.id].slots[slot.id]
			if ((equippable_in_this_slot ~= nil) and (equippable_in_this_slot ~= false)) then
				local len = #(ret[slot.en])
				ret[slot.en][len+1] = equipment_item
			end
		end
	end

	-- Rings and earrings are only flagged for the left slot, copy to right
	ret["Right Ear"] = ret["Left Ear"]
	ret["Right Ring"] = ret["Left Ring"]
	-- Weapons if dual wielding
	--[[ TODO:	Doesn't currently account for 2h weapons.
				Checking for restricted slots, as with other pieces of gear (robes etc.) is not the right way to do it since the slot is not restricted to i.e. grips.
				They also can't be considered in the same way that rings/earrings can.
				There needs to be special casing that says,
				"If the player has dual wield, all one-handed weapons should get copied to the sub slot"
	]]
	if (Client.player_utils.get_dual_wield_level(Client.get_player()) == 0) then
		for k, item in pairs(ret.Sub) do
			-- TODO: if equipppable in main, but not dual wield, remove from sub
			--ret.Sub[k] = v
			if res.items[item.id].slots[0] then
				ret.Sub[k] = nil
			end
		end
	end

	populate_gear_list_numerics(ret)
	return ret
end





local function filter_per_slot(categorized_gear_list, purpose)
	-- Do a little per-slot filtering of individual items,
	--  to remove complete garbage from the gear set permutation size.
	-- Build a naked set, plus the item in question, and filter them the same
	-- way as permutations use. Reset results between slots.

	-- TODO: Need the 2 best rings, earrings, weapons
	--  Right now it's including all rings etc. which does significantly impact
	--  permutation time. I think if we just eliminate the good ones from the first
	-- set of multi-slot items, then run it again and combine the good ones from both runs,
	-- that will still eliminate a lot while ensuring we have 2 good rings
	local static_zero_indices = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,[0]=0}
	local test_indices
	local test_results = {}
	local player = Client.get_player()
	local ret = {}
	local slot_name
	--print("BEFORE: " .. tostring(categorized_gear_list["Main"]))
	ret.Main = categorized_gear_list.Main
	ret.Sub = categorized_gear_list.Sub
	ret["Left Ear"] = categorized_gear_list["Left Ear"]
	ret["Right Ear"] = categorized_gear_list["Right Ear"]
	ret["Left Ring"] = categorized_gear_list["Left Ring"]
	ret["Right Ring"] = categorized_gear_list["Right Ring"]
	for iSlot = 0, 15 do
	--for _,iSlot in pairs({2,3,4,5,6,7,8,9,10,15}) do -- = 0, 15 do
		slot_name = resources.slots[iSlot].en
		test_results = {}
		for iItem = 1, #(categorized_gear_list[slot_name]) do
			--print("Slot " .. slot_name .. " item " .. iItem)
			--local item = categorized_gear_list[iSlot][iItem]
			test_indices = shallow_copy(static_zero_indices)
			test_indices[iSlot] = iItem
			add_and_filter_set_combination(test_results, purpose, 
			{
				gear_list_ref = categorized_gear_list,
				purpose_checked_against = purpose,
				indices = test_indices,
				apparent_utility_results = purpose.apparent_utility(categorized_gear_list, test_indices, player),
			})
		end
		--print(slot_name .. ": " .. #test_results .. " / " .. #(categorized_gear_list[slot_name]))
		local filtered_slot = {}
		for _,combo in pairs(test_results) do
			filtered_slot[#filtered_slot+1] = categorized_gear_list[iSlot][combo.indices[iSlot]]
		end
		
		-- Weapons, rings, earrings
		if iSlot == 0 or iSlot == 1 or (iSlot >= 11 and iSlot <= 14) then
			-- Again!
			local first_pass_results = test_results
			--print(slot_name .. ": " .. tcount(test_results) .. " items on first pass:")
			--for _,result in pairs(test_results) do
			--	print("  " .. resources.items[categorized_gear_list[iSlot][result.indices[iSlot]].id].en)
			--end
			test_results = {}
			for iItem = 1, #(categorized_gear_list[slot_name]) do
				local skip = false
				for iFirstPass = 1, #first_pass_results do
					--if categorized_gear_list[iSlot][iItem] == filtered_slot[iFirstPass] then skip = true end
					--print(array_tostring_horizontal(first_pass_results[iFirstPass].indices))
					if iItem == first_pass_results[iFirstPass].indices[iSlot] then skip = true end
				end
				if not skip then
					test_indices = shallow_copy(static_zero_indices)
					test_indices[iSlot] = iItem
					add_and_filter_set_combination(test_results, purpose, 
					{
						gear_list_ref = categorized_gear_list,
						purpose_checked_against = purpose,
						indices = test_indices,
						apparent_utility_results = purpose.apparent_utility(categorized_gear_list, test_indices, player),
					})
				else
					--print("skipping " .. resources.items[categorized_gear_list[iSlot][iItem].id	].en)
				end -- not skip
			end -- for iItem second pass
			-- TODO: (low pri) Maybe I could refactor this repetition into another function
			--print(slot_name .. ": " .. tcount(test_results) .. " items on second pass")
			--for _,result in pairs(test_results) do
			--	print("  " .. resources.items[categorized_gear_list[iSlot][result.indices[iSlot]].id].en)
			--end

			for _,combo in pairs(test_results) do
				filtered_slot[#filtered_slot+1] = categorized_gear_list[iSlot][combo.indices[iSlot]]
			end	
		end -- if ring earring weapon

		ret[resources.slots[iSlot].en] = filtered_slot
	end

	--print("AFTER: " .. tostring(ret["Main"]))
	populate_gear_list_numerics(ret)
	return ret
end





function estimate_permutation_size(categorized_gear_set)
	local ret = 1
	-- TODO: Be more accurate 2,10
	for iSlot = 0, 10 do
		local numThisSlot = categorized_gear_set.count[iSlot]
		if numThisSlot > 0 then
			ret = ret * numThisSlot
		end
	end

	-- Back
	if categorized_gear_set.count[15] > 0 then ret = ret * categorized_gear_set.count[15] end

	-- Earrings
	local num_earrings = categorized_gear_set.count[11]
	if num_earrings > 1 then
		ret = ret * (num_earrings * (num_earrings - 1)) / 2
	end

	-- Rings
	local num_rings = categorized_gear_set.count[13]
	if num_rings > 1 then
		ret = ret * (num_rings * (num_rings - 1)) / 2
	end
	return ret
end





--[[
function prune_sets(built_sets, purpose)
	local prevRangeStart = 1
	local prevRangeEnd = 1
	local curRangeStart = 1
	local curRangeEnd = 1
	local keep = false
	for dimension = 1, purpose.num_of_dimensions do
		table.sort(built_sets, function(a, b) return a.apparent_utility_results[dimension] > b.apparent_utility_results[dimension] end)
		curRangeStart = 0
		curRangeEnd = 0

		while curRangeEnd <= #built_sets do
			prevRangeStart = curRangeStart
			prevRangeEnd = curRangeEnd

			-- Scan ahead in the list for all elements which are equal in current dimension
			curRangeStart = prevRangeEnd + 1
			curRangeEnd = curRangeStart
			if (curRangeStart > #built_sets) then break end

			while curRangeEnd <= #built_sets and feq(built_sets[curRangeEnd].apparent_utility_results[dimension], built_sets[curRangeStart].apparent_utility_results[dimension]) do
				curRangeEnd = curRangeEnd + 1
			end
			curRangeEnd = curRangeEnd - 1

			-- Test for coincidence / equality among current range
			-- Meaning, not just the primary dimension, but all relevant utility metrics are equal
			local different
			for iCoincide = curRangeStart + 1, curRangeEnd do
				different = false
				for iDim = 1, purpose.num_of_dimensions do
					if not feq(built_sets[curRangeStart].apparent_utility_results[iDim], built_sets[iCoincide].apparent_utility_results[iDim]) then
						different = true
						break
					end
				end
				if not different then
					built_sets[iCoincide].need_to_delete = true
				end
			end
			
			-- Now test this equal range against the last equal range
			if prevRangeEnd > 0 and prevRangeStart > 0 then
				keep = false
				for iViableCurrent = curRangeStart, curRangeEnd do
					for iViablePrevious = prevRangeStart, prevRangeEnd do
						for dim_cmp = 1, purpose.num_of_dimensions do
							-- Is it better than something from the previous range
							-- in at least one way?
							if (built_sets[iViableCurrent] == nil) then
								warning("(debug) viable[" .. iViableCurrent .. "] == nil")
							end
							if (built_sets[iViablePrevious] == nil) then
								warning("(debug) viable[" .. iViablePrevious .. "] == nil")
							end
							if built_sets[iViableCurrent].apparent_utility_results[dim_cmp] > built_sets[iViablePrevious].apparent_utility_results[dim_cmp] then
								keep = true
								break
							end
						end
						if keep then break end
					end
					if not keep then
						built_sets[iViableCurrent].need_to_delete = true
					end
				end -- for iViableCurrent
			end -- if previous range in bounds
		end -- while curRangeEnd <= #built_sets

		-- Clean up .need_to_delete
		filter_array_in_place(built_sets, function(t) return (not t.need_to_delete) end)
	end -- for dimension = 1, purpose.num_of_dimensions

	for _,v in pairs(built_sets) do
		if v.need_to_delete then
			print("Detected a set flagged for deletion but still present.")
		end
	end


end -- function prune_sets
]]





local function initializer_factory(gear_list)
	local function _init_ring_or_earring_slots(set, bool_rings)
		local r_or_e
		local left_index
		if (bool_rings) then
			r_or_e = gear_list[13]
			left_index = 13
		else
			r_or_e = gear_list[11]
			left_index = 11
		end
		local init_value
		if (#r_or_e > 0) then init_value = 1 else init_value = 0 end
		-- Higher value should always be on the left, otherwise diagonalization of the iterator breaks
		if (#r_or_e >= 2) then
			set[left_index] = init_value + 1
			set[left_index+1] = init_value
		else
			set[left_index] = init_value
			set[left_index+1] = 0
		end
	end
	local r = {}
	r.init_rings    = function(set)  _init_ring_or_earring_slots(set, true)  end
	r.init_earrings = function(set)  _init_ring_or_earring_slots(set, false) end
	r.create_initial_set = function()
		local set = {}
		for _, sloti in pairs({0,1,2,3,4,5,6,7,8,9,10,15}) do
			local slot_name = resources.slots[sloti].en
			--if (#(gear_list[sloti]) >= 1) then
			if (#(gear_list[slot_name]) >= 1) then
				set[sloti] = 1
			else
				set[sloti] = 0
			end
		end
		r.init_rings(set)
		r.init_earrings(set)
		return set
	end
	return r
end





local function permutator_factory(gear_list)
	local initializer = initializer_factory(gear_list)
	--local sloti = 0
	return function(gear_indices) -- State-capturing custom iterator that uses the set and gear list to solve permuting sets
		local sloti = 0
		--gear_indices[0] = gear_indices[0] + 1
		while (sloti < 16) do
			if ((sloti < 11) or (sloti > 14)) then 
				-- "Normal" gear slots
				local init_value
				if (gear_list.count[sloti] > 0) then init_value = 1 else init_value = 0 end
				if (gear_indices[sloti] < gear_list.count[sloti]) then
					gear_indices[sloti] = gear_indices[sloti] + 1;
					return true
				else
					gear_indices[sloti] = init_value
				end
				sloti = sloti + 1
			else
				-- Rings and Earrings
				local r_or_e = gear_list[sloti]
				local init_value
				if (#r_or_e > 0) then init_value = 1 else init_value = 0 end
				if ((gear_indices[sloti] == gear_indices[sloti+1]) and (gear_indices[sloti] ~= 0)) then
					print("This shouldn't happen! Was the set list initialized with the same values in rings or earring slots?")
					return false
				elseif (gear_indices[sloti] < #r_or_e) then
					gear_indices[sloti] = gear_indices[sloti] + 1
					return true
				elseif ((gear_indices[sloti+1] < #r_or_e) and (gear_indices[sloti+1]+1 < gear_indices[sloti])) then
					gear_indices[sloti+1] = gear_indices[sloti+1] + 1
					gear_indices[sloti] = gear_indices[sloti+1] + 1
					return true
				else
					if ((sloti == 11) or (sloti == 12)) then
						initializer.init_earrings(gear_indices)
					elseif ((sloti == 13) or (sloti == 14)) then
						initializer.init_rings(gear_indices)
					end
				end
				sloti = sloti + 2
			end -- if ring/earring
			--[[
				A little extra time can be saved by also eliminating sets that use the identical
				type of item, under a different instance, but we need to be careful about
				checking whether that instance of item is different ala augmented, etc.
				i.e. There's no need to permute a ton of extra sets with a different instance of
				an Energy Earring unless that other instance has augments or something.
			]]
		end -- while (sloti < 16)
		return false
		--[[
			TODO: Mind the exclusion nature of weapons, shields, grips etc.
			i.e. 2h weapons only allow grips and such in the sub slot, not other 1h weapons
		]]
	end
end





function add_and_filter_set_combination(built_sets, purpose, new_element)
	local was_inserted = false
	local better_than_one_element_in_one_way = false
	local worse_than_one_element_in_all_ways = false
	g_count_add_and_filter_set_combination = (g_count_add_and_filter_set_combination or 0) + 1
	local iSet
	for iSet = 1, #built_sets do
		worse_than_one_element_in_all_ways = true
		for iDim = 1, purpose.num_of_dimensions do
			if new_element.apparent_utility_results[iDim] > built_sets[iSet].apparent_utility_results[iDim] then
				better_than_one_element_in_one_way = true
				worse_than_one_element_in_all_ways = false
				--break
			end
		end
		if worse_than_one_element_in_all_ways then break end
	end
	if worse_than_one_element_in_all_ways then
		--print("new thing sucks")
		return
	elseif better_than_one_element_in_one_way then
		--print("good for something")
		built_sets[#built_sets+1] = new_element
		was_inserted = true
	elseif #built_sets == 0 then
		--print("First item")
		built_sets[#built_sets+1] = new_element
		was_inserted = true
	end
	local count_prev_good = 0
	local count_prev_bad = 0
	if was_inserted then
		local keep = false
		for iSet = 1, #built_sets-1 do
			keep = false
			for iDim = 1, purpose.num_of_dimensions do
				if built_sets[iSet].apparent_utility_results[iDim] > new_element.apparent_utility_results[iDim] then
					keep = true
				end
			end
			if not keep then
				built_sets[iSet].need_to_delete = true
				count_prev_bad = count_prev_bad + 1
			else
				count_prev_good = count_prev_good + 1
			end
		end
		--print("Filtered " .. count_prev_bad .. ", kept " .. count_prev_good .. " combinations")
	else
		--print("Not inserted. @ " .. #built_sets .. " elements")
	end
	filter_array_in_place(built_sets, function(x) return (not x.need_to_delete) end)
	for _,v in pairs(built_sets) do
		if v.need_to_delete then
			warning("Detected a set flagged for deletion but still present.")
		end
	end
end






function get_gear_set_string(gear_list, cur_indices)
	local ret = "[["
	local item
	for i = 0, 15 do
		item = gear_list[i][cur_indices[i]]
		if item == nil then ret = ret .. ""
		else ret = ret .. resources.items[item.id].en
		end
		if i > 0 then ret = ret .. ", " end
	end
	ret = ret .. "]]"
	return ret
end





--local function build_gear_continuum(gear_list, purpose_name, done_callback)
function async_build_gear_continuum(purpose_name, done_callback)
	local purpose = PURPOSES[purpose_name]
	local categorized_gear_list = filter_per_slot(categorize_gear_by_slot(get_relevant_gear(purpose_name)), purpose) -- TODO: pass a table instead of a name

	-- Schema:
	-- categorized_gear_list[slot name][1~n] = an item
	-- e.g. categorized_gear_list["Head"][1].id  <-- is item id of an equippable head piece

	local cur_indices = initializer_factory(categorized_gear_list).create_initial_set()
	local permute = permutator_factory(categorized_gear_list)

	local count = 0
	local player = Client.get_player()
	local last_progress_report_time = os.time()
	local start_time = os.time()
	local is_long_mode_reported = false
	local capturable_purpose = purpose
	local total_permutations_estimate = estimate_permutation_size(categorized_gear_list)
	local done_promise = Promise.new()
	
	periodic_permute = function(cur_indices, built_sets, batch_size, count)
		local s = count
		local e = count + batch_size
		for i = s, e-1 do
			local next_element = {
			--built_sets[#built_sets+1] = {
				categorized_gear_list_ref = categorized_gear_list,
				purpose_checked_against = purpose,
				apparent_utility_results = purpose.apparent_utility(categorized_gear_list, cur_indices, player), -- Main evaluation for the purpose in question.
				indices = shallow_copy(cur_indices)
			}
			add_and_filter_set_combination(built_sets, purpose, next_element)
			count = count + 1
			
			local hard_cap_hit = false -- (count > MAX_ITERATIONS_LIMIT)
			local can_continue = permute(cur_indices) -- ADVANCES STATE IN-PLACE
			local STAHP = (hard_cap_hit or (not can_continue))
			--if (((count % PRUNE_SETS_INTERVAL_COUNT) == 0) or (STAHP)) then
			--	prune_sets(built_sets, purpose)
			--end
			if STAHP then
				-- TODO: If using promises, might want to reject with "too complex" error or something similar
				
				if (hard_cap_hit) then warning("Hard cap reached: " .. MAX_ITERATIONS_LIMIT .. " iterations.") end
				notice("Finished in " .. count .. " iterations.")
				--done_callback(built_sets)
				done_promise:resolve(built_sets)
				break
			end
			if (count == e) then
				local now = os.time()
				local tplus = os.difftime(now, start_time)
				if (tplus > LONG_MODE_START_TIME_SECONDS and not is_long_mode_reported) then
					notice("Entering long haul mode to avoid spam. Still working. Will report in " .. PROGRESS_REPORT_INTERVAL_MINUTES .. " minutes.")
					is_long_mode_reported = true
				end
				-- TODO: cur/max% report
				local delta_t = os.difftime(now, last_progress_report_time)
				if (delta_t > PROGRESS_REPORT_INTERVAL_MINUTES * 60)
					or (tplus < LONG_MODE_START_TIME_SECONDS and delta_t > 5)
				then
					notice("Progress: Found " .. #built_sets .. " gear sets from " .. count .. " / " .. total_permutations_estimate .. " combinations...")
					last_progress_report_time = now
				end
				schedule(function() periodic_permute(cur_indices, built_sets, batch_size, count) end, PERMUTE_BATCH_DELAY)
			end
		end -- for (batch_size)
	end --function periodic_permute

	notice("Estimated permutations for current inventory: " .. total_permutations_estimate)
	periodic_permute(cur_indices, {}, PERMUTE_BATCH_SIZE, 0, done_callback)
	return done_promise
end

