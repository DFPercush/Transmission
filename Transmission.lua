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

-- Windower components
require('chat')
require('logger')
local res = require("resources")
resources = res

-- This addon
require('util')
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

function filter_relevant(equipment_list, purpose)
	local ret = {}
	local has = false
	local relevant_stats
	if purposes[purpose] == nil then
		if modifiers[get_modifier_by_alias(purpose)] ~= nil then
			-- Allow a raw modifier name
			relevant_stats = { purpose }
		end
	else
		relevant_stats = purposes[purpose].relevant_modifiers
	end
	if tcount(relevant_stats) == 0 then
		warn("Unknown stat: " .. purpose)
		return equipment_list
	end

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
					ret[item.id] = item
					has = true
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
					ret[item.id] = item
					ret[item.id].storage = bagName
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
			ret[id] = item
		 end
	end
	return ret
end

function filter_is_equipment(items)
	local ret = {}
	for id, item in items do
		if res[item.id] ~= nil and (res.items[item.id].category == "Armor" or res.items[item.id].category == "Weapon") then
			ret [id] = item
		end
		
	end
	return ret
end

function filter_in_equippable_storage(items)
	local ret = {}
	for id,item in pairs(items) do
		if item.storage == "inventory" or item.storage == "wardrobe" or item.storage == "wardrobe2" or item.storage == "wardrobe3" or item.storage == "wardrobe4" then
			ret[id] = item
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
								ret[item.id] = item
								ret[item.id].storage = bagName
								-- Determine what stats this affects
							end
						else
							print("Item id " .. item.id)
						end -- items resource

						if item ~= nil and item.id ~= nil and res.item_descriptions[item.id] ~= nil then
							-- TODO: Parse stats
							if true then -- TODO: utility fn
								--notice(table.concat(string.split(res.item_descriptions[item.id].en, '\n'),' \\ '))
							end
						else
							--notice("(No description for item id " .. item.id .. ")")
						end -- item description resource
					--end -- item id nil/0
				end -- item nil/0
			end -- for items in bag
		end -- if valid bag
	end -- for bagId
	return ret
end

function get_relevant_gear(purpose)
	return filter_relevant(get_equippable_equipment(), purpose)
end


function categorize_gear_by_slot(gear_list)
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
				gear_list_copy[equipment_item_index] = nil
			end
		end
	end

	-- Rings and earrings are only flagged for the left slot, copy to right
	gear_list["Right Ear"] = gear_list["Left Ear"]
	gear_list["Right Ring"] = gear_list["Left Ring"]
	-- Weapons if dual wielding
	if get_dual_wield_level(get_player()) > 0 then
		for k, v in gear_list.Main do
			gear_list["Sub"][k] = v
		end
	end

	ret.count = {}
	ret.count[1] = tcount(ret.Main)
	ret.count[2] = tcount(ret.Sub)
	ret.count[3] = tcount(ret.Range)
	ret.count[4] = tcount(ret.Ammo)
	ret.count[5] = tcount(ret.Head)
	ret.count[6] = tcount(ret.Body)
	ret.count[7] = tcount(ret.Hands)
	ret.count[8] = tcount(ret.Legs)
	ret.count[9] = tcount(ret.Feet)
	ret.count[10] = tcount(ret.Neck)
	ret.count[11] = tcount(ret.Waist)
	ret.count[12] = tcount(ret["Left Ear"])
	ret.count[13] = tcount(ret["Right Ear"])
	ret.count[14] = tcount(ret["Left Ring"])
	ret.count[15] = tcount(ret["Right Ring"])
	ret.count[16] = tcount(ret.Back)
	ret[1]  = (ret.Main)
	ret[2]  = (ret.Sub)
	ret[3]  = (ret.Range)
	ret[4]  = (ret.Ammo)
	ret[5]  = (ret.Head)
	ret[6]  = (ret.Body)
	ret[7]  = (ret.Hands)
	ret[8]  = (ret.Legs)
	ret[9]  = (ret.Feet)
	ret[10]  = (ret.Neck)
	ret[11] = (ret.Waist)
	ret[12] = (ret["Left Ear"])
	ret[13] = (ret["Right Ear"])
	ret[14] = (ret["Left Ring"])
	ret[15] = (ret["Right Ring"])
	ret[16] = (ret.Back)
	return ret
end


local function prune_sets(built_sets, purpose)
	--[[
		built_sets:
			gear_list_ref{},
			purpose_checked_against{},
			apparent_utility_results[# of dimensions],
			indices[slots]
	]]

	local prevRangeStart = 1
	local prevRangeEnd = 1
	local curRangeStart = 1
	local curRangeEnd = 1
	local keep = false
	for dimension = 1,purpose.num_of_dimensions do
		table.sort(built_sets, function(a, b) return a.apparent_utility_results[dimension] > b.apparent_utility_results[dimension] end)
		curRangeStart = 1
		curRangeEnd = 1
		while curRangeEnd <= #built_sets do
			prevRangeStart = curRangeStart
			prevRangeEnd = curRangeEnd

			-- Scan ahead in the list for all elements which are equal in current dimension
			curRangeStart = prevRangeEnd + 1
			curRangeEnd = curRangeStart
			if (curRangeStart > #built_sets) then break end
			while curRangeEnd < #built_sets and feq(built_sets[curRangeEnd].apparent_utility_results[dimension], built_sets[i].apparent_utility_results[dimension]) do
				curRangeEnd = curRangeEnd + 1
			end
			
			-- Now test this equal range against the last equal range
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
			end -- for iCur
		end -- for i ... viable[i]

		-- Clean up .need_to_delete
		filter_array_in_place(built_sets, function(t) return t.need_to_delete end)
	end -- for dimension = 1, purpose.num_of_dimensions
end -- function prune_sets


function filter_dimensional(gear_list, purpose)
	-- Schema:
	-- gear_list[slot name][1~n] = an item
	-- e.g. gear_list["Head"][1].id  <-- is item id of an equippable head piece
	
	-- TODO: Separation of concerns: Building the permuted sets vs. evaluating if they're any good
	--[[ referenced_set = {
		gear_list_ref = gear_list
		indices = {#,#,#,#,#,#,#,#,#,#,#,#,#,#,#,#}
	} ]]
	local cur = {0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1}
	local min = shallow_copy(cur)
	min[1] = 1
	local max = {}
	for x=1,16 do
		max[x] = tcount(gear_list[x])
	end

	print("max = " .. tostring(max))
	
	local count = 0
	local built_sets = {}
	local player = get_player()
	local result


	--local built_sets_last_index
	--local min_bonuses = {}
	--repeat -- main combinator loop
	print("cur at start = " .. tostring(cur))
	while multi_dimension_next(cur, min, max) do
		print("sanity check ".. count)

		result = {}

		-- Skip duplicate items in rings, earrings and weapons.
		-- Since this tests for equal table references, two distinct items of the
		-- same id will still be able to be equipped.

		print("cur = " .. tostring(cur))
		print("cur[flags.slot_index[Left Ear]] = " .. cur[flags.slot_index["Left Ear"]])
		print("cur[flags.slot_index[Right Ear]] = ".. cur[flags.slot_index["Right Ear"]]
	)
		if (cur[flags.slot_index["Left Ear"]] ~= cur[flags.slot_index["Right Ear"]])
		 and (cur[flags.slot_index["Left Ring"]] ~= cur[flags.slot_index["Right Ring"]])
		 and (cur[flags.slot_index["Main"]] ~= cur[flags.slot_index["Sub"]])
		 then
			print("dbg 2")
			-- TODO: Are there any restricted slots? (tunics remove headgear, etc)
			for k,v in pairs(cur) do
				--if RESTRICTED_SLOTS[gear_set[k][v]]
			end

			-- Store the utility results and a way to reference the gear set it's looking at
			-- TODO: +? convert code that expects built_set[dimension] to built_sets.apparent_utility_results[dimension]
			built_sets[#built_sets+1] = {
				gear_list_ref = gear_list,
				purpose_checked_against = purpose,
				apparent_utility_results = purpose.apparent_utility(gear_list, cur, player), -- Main evaluation for the purpose in question.
				indices = shallow_copy(cur)
			}

			-- To extract the gear set and equip it, you will need gear_set as well as viable[x].indeces
			-- for each slot, equip gear_set[slot_name][viable[x].indeces[slot_id]]

			count = count + 1
			--print("viable = " .. tostring(viable))
		end


		-- TODO: Remove limiter
		if count > 1e6 then return 0 end


		if (count % 10000 == 0) then
			print(cur[1] .. ", " .. cur[2] .. ", " .. cur[3] .. ", " .. cur[4] .. ", " .. cur[5] .. ", " .. cur[6] .. ", " .. cur[7] .. ", " .. cur[8] .. ", " .. cur[9] .. ", " .. cur[10] .. ", " .. cur[11] .. ", " .. cur[12] .. ", " .. cur[13] .. ", " .. cur[14] .. ", " .. cur[15] .. ", " .. cur[16])
			
			prune_sets(built_sets, purpose)
		end -- if count % something
	--until multi_for_next(cur, min, max) == false
	end

	-- Once more with feeling
	prune_sets(built_sets, purpose)

	print("filter_dimensional: " .. count .. " iterations complete.")
	print(#built_sets .. " viable sets")
	print(" [1] = ")
	print(built_sets[1])
end


-- TODO: Rewrite this such that it holds one piece of gear constant at a time and scans all other sets with that piece of gear.
--		 Track which pieces of gear this operation has been completed for, and upon encountering a piece of gear in further permutations, skip.
--		 Report to player chat regarding the progress of scanning their equipment,
--		 e.g. in chat:
--				Exhaustive analysis of Joyeuse paired with all other equipment complete.
--				x% of equipment analyzed (1/400). Time elapsed: ##:##:## for Joyeuse; ##:##:## total.
--				Starting evaluation of Genbu's Shield in the background...
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


--windower.register_event('action message',function (actor_id, target_id, actor_index, target_index, message_id, param_one, param_2, param_3)
--	--if actor_id ~= windower.ffxi.get_player().id then return end
--	log("Message " .. message_id)
--end)



































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

	-- [[
	local result = filter_dimensional(categorize_gear_by_slot(get_relevant_gear("auto_attack")), purposes.auto_attack)
	print(" ------- DING, FRIES ARE DONE -------")
	print("result is a " .. type(result)) -- .. " : " .. tostring(result))
	if type(result) == "table" then
		print(tcount(result) .. " entries")
	end
	result = nil
	--]]

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

