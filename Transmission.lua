-- TODO:
	-- stats_i_care_about_on("war", "auto_attack", "ws", "def" ...)
		-- or ("rng", {ratt=100, racc=75, ...}, {exclude_list})
	-- loadout("rng") -- pull from storage
	--
	-- set_priority_multiplier(number) -- ratio of how much of higher priority stat to give up for a lower priority stat

_addon.name	   = 'Transmission'
_addon.author  = 'DFPercush'
_addon.version = '0.0.1'
_addon.commands = {'tm', 'transmission'}




-- Config
MAX_ITERATIONS_LIMIT = 10000  -- hard fail safe on max run time
PRUNE_SETS_INTERVAL_COUNT = 100  -- number of combinations to accumulate before pruning
local PERMUTE_BATCH_SIZE = 100  -- Set combinations
local PERMUTE_BATCH_INTERVAL_TIME = 1 -- Seconds
-- There is also TEST_COMBINATION_FUNCTION - use search, must be defined below

-- Windower components
require('chat')
require('logger')
local res = require("resources")
resources = res
__OUTSTANDING_COROUTINES__ = {}
function schedule(f,t) local id = coroutine.schedule(f,t); table.insert(__OUTSTANDING_COROUTINES__, id) end
windower.register_event('unload',function ()
	for i, coroutine_id in pairs(__OUTSTANDING_COROUTINES__) do
		coroutine.close(coroutine_id)
	end
end)

-- This addon
require('util')
require('generate_useful_combinations_v1')
local flags = require('flags')
TM_FLAGS = flags
local job_flags = flags.job_flags
local job_index = flags.job_index
--local slot_flags = flags.slot_flags
require("modifier_aliases")
require("multi_hit_weapons")

-- From topaz/src/modifier.h
-- cat mods-enum-cpp.txt | sed s/\\\ *\\\([A-Za-z0-9_]*\\\)\\\ *=\\\ *\\\([0-9]*\\\).*/\\\[\\\2\\\]=\\\"\\\1\\\",/ > modifiers.lua
-- will require slight editing at beginning and end of file
local modifiers = require("modifiers")
	-- two-way mapping for modifiers
	for k,v in pairs(modifiers) do
		modifiers[v] = k
	end


	

-- From sql/item_mods.sql
-- OLD: cat item_mods.sql | sed s/[^0-9]*\\\([0-9]*\\\),\\\([0-9]*\\\),\\\([0-9-]*\\\).*/\{item_id=\\1,mod=\\2,value=\\3\},/ > item_mods_data.lua
-- cat item_mods.sql | sed s/[^0-9\\-]*\\\([0-9]*\\\),\\\([0-9]*\\\),\\\([0-9-]*\\\).*/\{item_id=\\1,mod=\\2,value=\\3\},/ > item_mods_data.lua
local item_mods_data = require("item_mods_data")

-- SELECT itemId,dmg,delay FROM item_weapon;
-- cat weapon_dmg_delay.csv | sed s/\\\([0-9]*\\\),\\\([0-9]*\\\),\\\([0-9]*\\\)/\\\{item_id=\\1,dmg=\\2,delay=\\3\\\},/ > weapon_dmg_delay.lua
require("weapon_dmg_delay")
for _,weapon_info in pairs(WEAPON_DAMAGE_DELAY) do
	if forcenumber(weapon_info.dmg) ~= 0 then
		item_mods_data[#item_mods_data+1] = {
			item_id=weapon_info.item_id,
			mod=160, -- DMG
			value=weapon_info.dmg
		}
		item_mods_data[#item_mods_data+1] = {
			item_id=weapon_info.item_id,
			mod=171, -- DELAY
			value=weapon_info.delay
		}
	end
end

item_mods = {}
	-- convert relational database data to tables
	-- item_mods[item_id][mod_index] = amount
	for _,mod in pairs(item_mods_data) do
		item_mods[mod.item_id] = item_mods[mod.item_id] or {}
		item_mods[mod.item_id][mod.mod] = mod.value
	end
item_mods_data = nil

-- Here, a purpose means any action (like a spell, ability, or weapon skill),
--	or state (like auto_attack, idle/movement speed), which can be boosted by gear.
local purposes = require("purposes")

require("rslot")




--windower.register_event("action", function(ac)
	--if ac.actor_id ~= windower.ffxi.get_player().id then return end
	--if ac.category ~= 8 then return end -- spell cast start
	--log("Action " .. ac.category .. ":" .. ac.param)
--end)


function can_equip(item, player_optional)
	--things to check: race/gender, job, level
	-- TODO: Filter only category
	local player = player_optional or get_player()
	local res_item = res.items[item.id]
	if res_item.category ~= "Weapon" and res_item.category ~= "Armor" then return false end

	if item ~= nil and item.id ~= nil and res.items[item.id] ~= nil then
		--print("races")
		--print(res_item.races)
		--if not testflag(res_item.races, 2^player.race) then return false end
		--if not testflag(res_item.jobs, job_flags[player.main_job]) then return false end
		if not res_item.races[player.race] then return false end
		if not res_item.jobs[job_index[player.main_job]] then return false end
		if player.main_job_level < res_item.level then return false end
		return true
	end
	return false
end

function filter_relevant(equipment_list, purpose_name)

	-- debugging
	print("Filter dimensional: equipment list has length " .. #equipment_list)
	for k,v in pairs(equipment_list) do
		local tmpName = resources.items[v.id].en
		if string.find(tmpName, "Courage") then
			print("Original list hit for " .. tmpName)
		end
	end

	local ret = {}
	local has = false
	local relevant_stats
	local purpose = purposes[purpose_name]
	if purpose == nil then
		if modifiers[get_modifier_by_alias(purpose_name)] ~= nil then
			-- Allow a raw modifier name
			relevant_stats = { purpose_name }
		end
	else
		relevant_stats = purposes[purpose_name].relevant_modifiers
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
			--Schema: item_mods[id][modIndex] = value
			--local mod_id = modifiers[mod_text]
			local mod_id = modifiers[get_modifier_by_alias(mod_text)]
			if item_mods[item.id] ~= nil
			 and item_mods[item.id][mod_id] ~= nil
			 and item_mods[item.id][mod_id] ~= 0
			 then
				good_item = true
				-- is it actually a bonus, or a detriment
				if (item_mods[item.id][mod_id] > 0) or
				 ((purpose.want_negative ~= nil) and (purpose.want_negative[mod_text])) then
					print(tostring(item.storage) .. "/" .. item_name(item) .. " has " .. mod_text)
					
					-- Prevent duplicates like multiple stacks of ammo, randomly dropped armor etc
					local num_this_item = 0
					for iRet = 1, #ret do
						if ret[iRet].id == item.id then num_this_item = num_this_item + 1 end
					end
					if num_this_item < quantity_limits[get_equipment_slot_id_of_item(item)] then
						local nextIndex = #ret+1
						ret[nextIndex] = shallow_copy(item)
						has = true
					end
					break
				end
			end
		end
		if not has then
			--print(item_name(item) .. " is not relevant")
		end
	end

	--print(tcount(ret) .. " items")
	return ret
end


function get_all_items()
	local bags = windower.ffxi.get_items()
	local ret = {}
	for bagName,bag in pairs(bags) do
		for _, item in pairs(bag) do
			if type(item) == 'table' and item.id ~= nil and item.id > 0 then
				if res.items[item.id] ~= nil
				--and (res.items[item.id].category == "Armor" or res.items[item.id].category == "Weapon")
				then
					--ret[item.id] = item
					--ret[item.id].storage = bagName
					
					local nextIndex = #ret
					ret[nextIndex] = shallow_copy(item)
					ret[nextIndex].storage = bagName
				end
			end
		end
	end
	return ret
end

function get_all_equipment()
	local ret = {}
	for id, item in pairs(get_all_items()) do
		if res.items[item.id] ~= nil
		 and (res.items[item.id].category == "Armor" or res.items[item.id].category == "Weapon")
		 then
			--ret[id] = item
			ret[#ret+1] = item
		 end
	end
	return ret
end

function filter_is_equipment(items)
	local ret = {}
	for _, item in items do
		if res[item.id] ~= nil and (res.items[item.id].category == "Armor" or res.items[item.id].category == "Weapon") then
			--ret [id] = item
			local nextIndex = #ret
			ret[nextIndex] = shallow_copy(item)
		end
		
	end
	return ret
end

function filter_in_equippable_storage(items)
	local ret = {}
	for _,item in pairs(items) do
		if item.storage == "inventory" or item.storage == "wardrobe" or item.storage == "wardrobe2" or item.storage == "wardrobe3" or item.storage == "wardrobe4" then
			--ret[id] = item
			local nextIndex = #ret
			ret[nextIndex] = shallow_copy(item)
		end
	end
	return ret
end

function get_equippable_equipment()
	--notice("Boop")
	--notice("p1=" .. p1 .. "  p2=" .. p2)
	local count = 0
	local bags = windower.ffxi.get_items()
	local player = get_player()
	local ret = {}
	local num_added = 0
	--print(bags)

	--res.items:with("id",
	--(RESOURCES.item_descriptions[id].en)


	--for k,v in pairs(bags) do
	--	if type(v) == 'table' then
	--		print(k)
	--	end
	--end

	-- temp
	ar1 = "auto_attack"

	-- categories are "Weapon", "Armor", "Usable", "General"

	for bagName,bag in pairs(bags) do
		--notice(len(bags) .. " bags")
		--bag = windower.ffxi.get_items(bagId)
		--print(bag)
		if (bagName == "inventory") or (bagName == "wardrobe") or (bagName == "wardrobe2") or (bagName == "wardrobe3") or (bagName == "wardrobe4") then
			for _, item in pairs(bag) do
				if type(item) == 'table' and item.id ~= nil and item.id > 0 then
					--if (item.id ~= nil) and (item.id ~= 0) then
						if res.items[item.id] ~= nil
						 --and (res.items[item.id].category == "Armor" or res.items[item.id].category == "Weapon")
						 then
							if can_equip(item, player) then
								--print(res.items[item.id].en)
								--ret[#ret+1] = item
								
								--ret[item.id] = item
								--ret[item.id].storage = bagName

								local nextIndex = #ret+1
								ret[nextIndex] = shallow_copy(item)
								ret[nextIndex].storage = bagName
								num_added = num_added + 1
							end
						else
							warn("No resource for item id " .. item.id)
						end -- items resource
					--end -- item id nil/0
				end -- item nil/0
			end -- for items in bag
		end -- if valid bag
	end -- for bagId

	print("get_equippable_equipment() added " .. num_added .. " items, returning " .. #ret .. " items")
	return ret
end

function get_relevant_gear(purpose_name)
	return filter_relevant(get_equippable_equipment(), purpose_name)
end


function categorize_gear_by_slot(gear_list)
	local ret = {}
	local gear_list_copy = shallow_copy(gear_list)
	print("categorize_gear_by_slot: gear_list = ")
	--print(gear_list)
	for k,item in pairs(gear_list) do
		print("  [" .. k .. "] = " .. resources.items[item.id].en)	
	end
	for _, slot in pairs(res.slots) do
		ret[slot.en] = {}
		for equipment_item_index, equipment_item in pairs(gear_list_copy) do
			--print(res.items[equipment_item.id].slots)
			--if testbit(res.items[equipment_item.id].slots, 2^slot.id) then
			local equippable_in_this_slot = res.items[equipment_item.id].slots[slot.id]
			if ((equippable_in_this_slot ~= nil) and (equippable_in_this_slot ~= false)) then
				local len = #(ret[slot.en])
				ret[slot.en][len+1] = equipment_item
				gear_list_copy[equipment_item_index] = nil
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
	if get_dual_wield_level(get_player()) > 0 then
		for k, v in pairs(ret.Main) do
			ret["Sub"][k] = v
		end
	end

	ret.count = {}
	for _,slot in pairs(resources.slots) do
		ret[slot.id] = ret[slot.en]
		ret.count[slot.id] = tcount(ret[slot.en])
	end
	return ret
end


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

		print("built_sets = ...")
		for _,v in pairs(built_sets) do
			print("  " .. array_tostring_horizontal(v.apparent_utility_results))
		end

		while curRangeEnd <= #built_sets do
			prevRangeStart = curRangeStart
			prevRangeEnd = curRangeEnd

			-- Scan ahead in the list for all elements which are equal in current dimension
			curRangeStart = prevRangeEnd + 1
			curRangeEnd = curRangeStart
			if (curRangeStart > #built_sets) then break end

			--print("curRangeEnd")
			while curRangeEnd <= #built_sets and feq(built_sets[curRangeEnd].apparent_utility_results[dimension], built_sets[curRangeStart].apparent_utility_results[dimension]) do
				print("Current range (dim " .. dimension .. ") " .. built_sets[curRangeEnd].apparent_utility_results[dimension] .. " == " .. built_sets[curRangeStart].apparent_utility_results[dimension])
				curRangeEnd = curRangeEnd + 1
			end
			curRangeEnd = curRangeEnd - 1

			print("[" .. prevRangeStart .. "-" .. prevRangeEnd .. "] <> [" .. curRangeStart .. "-" .. curRangeEnd .. "]")

			-- Test for coincidence / equality among current range
			-- Meaning, not just the primary dimension, but all relevant utility metrics are equal
			local different
			for iCoincide = curRangeStart + 1, curRangeEnd do
				different = false
				print(array_tostring_horizontal(built_sets[curRangeStart].apparent_utility_results) .. " =? " .. 
				      array_tostring_horizontal(built_sets[iCoincide    ].apparent_utility_results))
				for iDim = 1, purpose.num_of_dimensions do
					--print(built_sets[curRangeStart].apparent_utility_results[iDim] .. " =? " .. built_sets[iCoincide].apparent_utility_results[iDim])
					if not feq(built_sets[curRangeStart].apparent_utility_results[iDim], built_sets[iCoincide].apparent_utility_results[iDim]) then
						different = true
						break
					end
				end
				if not different then
					print("equal")
					built_sets[iCoincide].need_to_delete = true
				else print("not equal")
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
								print("(debug) viable[" .. iViableCurrent .. "] == nil")
							end
							if (built_sets[iViablePrevious] == nil) then
								print("(debug) viable[" .. iViablePrevious .. "] == nil")
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
		filter_array_in_place(built_sets, function(t) return t.need_to_delete end)
	end -- for dimension = 1, purpose.num_of_dimensions

	for _,v in pairs(built_sets) do
		if v.need_to_delete then
			print("Detected a set flagged for deletion but still present.")
		end
	end


end -- function prune_sets

local function initializer_factory(gear_list)
	local function _init_ring_or_earring_slots(set, bool_rings)
		local r_or_e
		local left_index
		if (bool_rings) then
			r_or_e = gear_list[11]
			left_index = 11
		else
			r_or_e = gear_list[13]
			left_index = 13
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
	r = {}
	r.init_rings    = function(set)  _init_ring_or_earring_slots(set, true)  end
	r.init_earrings = function(set)  _init_ring_or_earring_slots(set, false) end
	r.create_initial_set = function()
		local set = {}
		for _, sloti in pairs({0,1,2,3,4,5,6,7,8,9,10,15}) do
			if (#(gear_list[sloti]) >= 1) then
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

g_temp_counter = 0

local function iterator_factory(gear_list)
	local initializer = initializer_factory(gear_list)
	return function(gear_indices) -- State-capturing custom iterator that uses the set and gear list to solve permuting sets
		g_temp_counter = g_temp_counter + 1
		local print_everything = false
		if ((g_temp_counter > 16) and (g_temp_counter < 20)) then 
			print_everything = true
		end
		
		local sloti = 0
		if print_everything then print(" ") end
		if print_everything then print("Entering iterator function...") end
		while (sloti <= #gear_indices) do
			if print_everything then print("sloti = " .. sloti) end
			if ((sloti < 11) or (sloti > 14)) then 
				if print_everything then print("Entered normal gear branch") end
				-- "Normal" gear slots
				local init_value
				if (gear_list.count[sloti] > 0) then init_value = 1 else init_value = 0 end
				if print_everything then print("init_value = " .. init_value) end
				if (gear_indices[sloti] < gear_list.count[sloti]) then
					if print_everything then print("         " .. zero_based_array_tostring_horizontal(gear_indices) .. " -> ") end
					gear_indices[sloti] = gear_indices[sloti] + 1;
					print("         " .. zero_based_array_tostring_horizontal(gear_indices))
					if print_everything then print("Exiting iterator function with true...") end
					return true
				else
					if print_everything then print("Maxed out on " .. resources.slots[sloti].en) end
					gear_indices[sloti] = init_value
					if print_everything then print("Reinitialized " .. resources.slots[sloti].en .. " to " .. init_value) end
				end
				if print_everything then print("Incrementing sloti by 1 and looping...") end
				sloti = sloti + 1
			else
				-- Rings and Earrings
				if print_everything then print("Entered [ear]ring branch with sloti of " .. sloti) end
				local r_or_e = gear_list[sloti]
				local init_value
				if (#r_or_e > 0) then init_value = 1 else init_value = 0 end
				if print_everything then print("Init value = " .. init_value) end
				if (gear_indices[sloti] == gear_indices[sloti+1]) then
					print("This shouldn't happen! Was the set list initialized with the same values in rings or earring slots?")
					return false
				elseif (gear_indices[sloti] < #r_or_e) then
					if print_everything then print("         " .. zero_based_array_tostring_horizontal(gear_indices) .. " -> ") end
					gear_indices[sloti] = gear_indices[sloti] + 1
					print("         " .. zero_based_array_tostring_horizontal(gear_indices))
					if print_everything then print("Exiting iterator function with true (1)...") end
					return true
				--elseif ((gear_indices[sloti+1] < #r_or_e) and (#r_or_e >= 2)) then
				elseif ((gear_indices[sloti+1] < #r_or_e) and (gear_indices[sloti+1]+1 < gear_indices[sloti])) then
					if print_everything then print("         " .. zero_based_array_tostring_horizontal(gear_indices) .. " -> ") end
					gear_indices[sloti+1] = gear_indices[sloti+1] + 1
					gear_indices[sloti] = gear_indices[sloti+1] + 1
					print("         " .. zero_based_array_tostring_horizontal(gear_indices))
					if print_everything then print("Exiting iterator function with true (2)...") end
					return true
				else
					if print_everything then print("Maxed out on " .. resources.slots[sloti].en) end
					-- lol {initializer.rings, initializer.earrings}[{[11]=1,[12]=1,[13]=2,[14]=2}[sloti]](gear_indices)
					if ((sloti == 11) or (sloti == 12)) then
						initializer.init_earrings(gear_indices)
					elseif ((sloti == 13) or (sloti == 14)) then
						initializer.init_rings(gear_indices)
					end
					if print_everything then print("Reinitialized slots to {[" .. sloti .. "] = " .. gear_indices[sloti] .. ", [" .. sloti+1 .. "] = " .. gear_indices[sloti+1] .. "}") end
					--set[sloti] = init_value
					--if (#r_or_e >= 2) then set[sloti+1] = init_value + 1 else set[sloti+1] = 0 end
				end
				if print_everything then print("Incrementing sloti by 2 and looping...") end
				sloti = sloti + 2
			end
			--[[
				A little extra time can be saved by also eliminating sets that use the identical
				type of item, under a different instance, but we need to be careful about
				checking whether that instance of item is different ala augmented, etc.
				i.e. There's no need to permute a ton of extra sets with a different instance of
				an Energy Earring unless that other instance has augments or something.
			]]
		end
		return false
		--[[
			TODO: Special casing for rings and earrings, i.e:

			TODO: Mind the exclusion nature of weapons, shields, grips etc.
			i.e. 2h weapons only allow grips and such in the sub slot, not other 1h weapons
		]]
	end
end


function filter_dimensional(gear_list, purpose, done_callback)
	-- Schema:
	-- gear_list[slot name][1~n] = an item
	-- e.g. gear_list["Head"][1].id  <-- is item id of an equippable head piece

	local cur_indices = initializer_factory(gear_list).create_initial_set()
	local iterator = iterator_factory(gear_list)

	local count = 0
	local built_sets = {}
	local player = get_player()
	print("cur at start = " .. array_tostring_horizontal(cur_indices))
	capturable_purpose = purpose
	
	periodic_permute = function(cur_indices, built_sets, batch_size, count, done_callback)
		local s = count
		local e = count + batch_size
		for i = s, e-1 do 
			if(iterator(cur_indices)) then
				--print(count .. " : " .. array_tostring_horizontal(cur_indices))
				--print(gear_list.Range)
				built_sets[#built_sets+1] = {
					gear_list_ref = gear_list,
					purpose_checked_against = purpose,
					apparent_utility_results = purpose.apparent_utility(gear_list, cur_indices, player), -- Main evaluation for the purpose in question.
					indices = shallow_copy(cur_indices)
				}
				if ((count % PRUNE_SETS_INTERVAL_COUNT) == 0) then
					prune_sets(built_sets, purpose)
				end
				count = count + 1
				if (count == e) then
					schedule(function() periodic_permute(cur_indices, built_sets, batch_size, count, done_callback) end, PERMUTE_BATCH_INTERVAL_TIME)
				end
			else
				prune_sets(built_sets, capturable_purpose)
				notice(count .. " iterations complete.")
				print(#built_sets .. " viable sets")
				done_callback(built_sets)
				break
			end -- if increment_in_place...
		end -- for (batch_size)
	end --function periodic_permute

	periodic_permute(cur_indices, built_sets, PERMUTE_BATCH_SIZE, 0, done_callback)

	--[[
	while(increment_set_in_place(cur_indices)) do
		built_sets[#built_sets+1] = {
			gear_list_ref = gear_list,
			purpose_checked_against = purpose,
			apparent_utility_results = purpose.apparent_utility(gear_list, cur_indices, player), -- Main evaluation for the purpose in question.
			indices = shallow_copy(cur_indices)
		}
		if (count > MAX_ITERATIONS_LIMIT) then
			print("Reached MAX_ITERATIONS_LIMIT of " .. MAX_ITERATIONS_LIMIT)
			break
		end
		if ((count % PRUNE_SETS_INTERVAL) == 0) then
			prune_sets(built_sets, purpose)
		end
		count = count + 1
		end -- Main iterator for combinations of gear
	prune_sets(built_sets, purpose)

	print("filter_dimensional: " .. count .. " iterations complete.")
	print(#built_sets .. " viable sets")
	]]
	--print(" [1] = ")
	--print(built_sets[1])
	--print("set 1: " .. get_gear_set_string(gear_list, built_sets[1].indices))
	return built_sets
end

function get_gear_set_string(gear_list, cur_indices)
	-- TODO: Check off-by-one indices with gear slots? starts at 0 in resources
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

-- TODO: Rewrite this such that it holds one piece of gear constant at a time and scans all other sets with that piece of gear.
--		 Track which pieces of gear this operation has been completed for, and upon encountering a piece of gear in further permutations, skip.
--		 Report to player chat regarding the progress of scanning their equipment,
--		 e.g. in chat:
--				Exhaustive analysis of Joyeuse paired with all other equipment complete.
--				x% of equipment analyzed (1/400). Time elapsed: ##:##:## for Joyeuse; ##:##:## total.
--				Starting evaluation of Genbu's Shield in the background...
--[[
num_permute_calls = 0
function evaluate_set_permutations(gear_list, utility_function)

	function permute_gear(current_slot_id, growing_set)

		num_permute_calls = num_permute_calls + 1
		--if num_permute_calls > 10000000 then return {} end
		--if (current_slot_id == 9) then
		--	print("still working... slot=" .. current_slot_id .. " & " .. tostring(num_permute_calls) ..  " calls so far")
		--end
		if num_permute_calls % 100000 == 0 then
			filter_dimensional()
			notice("Progress:" .. tcount(gear_list) .. " viable sets found in " .. num_permute_calls .. " / " .. goal_permute_calls .. " gear set combinations.")
		end

		local built_sets = {}
		local my_set = shallow_copy(growing_set)
		local this_slot_name = res.slots[current_slot_id].en
		local gear_for_this_slot = gear_list[this_slot_name]
		-- TODO: Filter by "more useful in at least one way than the minimum"
		if ((#gear_for_this_slot == 0) and (current_slot_id < #(res.slots))) then
			append(built_sets, permute_gear(current_slot_id + 1, my_set))
		end
		for _, equipment_item in pairs(gear_for_this_slot) do
			my_set[this_slot_name] = equipment_item
			if (current_slot_id < #(res.slots)) then
				--built_sets[#built_sets+1] = permute_gear(current_slot_id + 1, my_set) -- Don't nest built_sets
				append(built_sets, permute_gear(current_slot_id + 1, my_set))
			else
				-- We have a finished set once the recursion reaches 16 depth
				built_sets[#built_sets+1] = my_set
			end
		end

		return built_sets
	end

	num_permute_calls = 0
	goal_permute_calls = 1
	for k,v in pairs(gear_list) do
		print(k)
		--print(v)
		if tcount(v) > 0 then goal_permute_calls = goal_permute_calls * tcount(v) end
		print("tcount(v) = " .. tcount(v) .. "  --- total " .. goal_permute_calls)
	end
	print("Would run " .. goal_permute_calls .. "permutations")
	--return #(permute_gear(0, {}))
	return 0

	--categorized_gear_list = categorize_gear_by_slot(gear_list)
	--local i1 = 0
	--while(i1 < #(res.slots)) do
	--	local slot_name_a = res.slots[i1].en
	--	local i2 = i1 + 1
	--	while i2 < #(res.slots) do
	--		local slot_name_2 = res.slots[i2].en
	--		
	--		i2 = i2 + 1
	--	end
	--	i1 = i1 + 1
	--end
end
]]

--windower.register_event('action message',function (actor_id, target_id, actor_index, target_index, message_id, param_one, param_2, param_3)
--	--if actor_id ~= windower.ffxi.get_player().id then return end
--	log("Message " .. message_id)
--end)

function test_multi_dimension_iterator()
	local cur = {-1,0,0}
	local min = {0,0,0}
	local max = {2,2,2}
	local count = 0
	while multi_dimension_next(cur,min,max) do
		print(array_tostring_horizontal(cur))
		count = count + 1
		if count > 30 then
			print("Warning: Fail safe stopped the loop")
			break
		end
	end
	print("Last: " .. array_tostring_horizontal(cur))
end































--local TEST_COMBINATION_FUNCTION = generate_useful_combinations_v1
local TEST_COMBINATION_FUNCTION = filter_dimensional

handle_command = function(p1, p2)
	--local target = windower.ffxi.get_mob_by_target("t")
	--print(target)

	--local player = get_player()
	--print(player.main_job .. player.main_job_level)

	--print(get_player())
	

	--print(nil > 0)

	--print(#require("modifications"))

	--print(item_mods[13259])
	--if modifiers[mod] ~= nil
	--print(item_mods[13259][modifiers["AGI"]])

	--print(res.items[16713].skill) -- number/index

	--print("sadfgadfg")

	--local result = evaluate_set_permutations(categorize_gear_by_slot(get_relevant_gear("auto_attack")))


	-- test_multi_dimension_iterator() if true then return end

	--print(resources.slots); if true then return end

	--local result = filter_dimensional(categorize_gear_by_slot(get_relevant_gear("auto_attack")), purposes.auto_attack)
	--filter_dimensional(categorize_gear_by_slot(get_relevant_gear("auto_attack")), purposes.auto_attack,

	--local test = { [0] = true, [1] = true, [2] = true };print(tostring(#test)); if true then return end

	--print("feq test: " .. tostring(feq(1.234, 1.2345))); if true then return end

	local relevant_gear = get_relevant_gear("auto_attack")
	local categorized_gear = categorize_gear_by_slot(relevant_gear)
	TEST_COMBINATION_FUNCTION(categorized_gear, purposes.auto_attack,
		function(result)
			print(" ------- DING, FRIES ARE DONE -------")
			print("result is a " .. type(result)) -- .. " : " .. tostring(result))
			if type(result) == "table" then
				print(tcount(result) .. " entries")
			end
			for k,v in pairs(result) do
				print(get_gear_set_string(v.gear_list_ref, v.indices) .. " : " .. array_tostring_horizontal(v.apparent_utility_results))
				--print(categorized_gear.Ammo[v.indices[3]].slot) -- TODO: multiple stacks of ammo will fuck it up
			end
		end
	)

	--print(resources.slots)

	--print(get_modifier_id("atk"))

end


xhandle_command = function()
	--local available = get_equippable_equipment()
	--local filtered = filter_relevant(available, "auto_attack")
	print("----- Gear that affects: auto_attack -----")
	for _, item in pairs(get_relevant_gear("auto_attack")) do
		print(res.items[item.id].en)
	end
end

windower.register_event('addon command', handle_command)

