require('util')
local windower_player_utils = require "windower_player_utils"
local slips = require('slips')

local R = {
	flags = require('flags')
}
res = require('resources')

R.bag_double_map = {}
for k, v in pairs(res.bags) do
	R.bag_double_map[v.id] = v.en
	local strings = {v.en, string.lower(v.en), string.upper(v.en)}
	for _, str in pairs(strings) do
		R.bag_double_map[str] = v.id
		local spaceless = ""
		local with_underscore = ""
		for i=0,#str do
			local char = string.sub(str, i, i)
			if (char == " ") then
				with_underscore = with_underscore .. "_"
			else
				spaceless = spaceless .. char
				with_underscore = with_underscore .. char
			end
		end
		R.bag_double_map[spaceless] = v.id
		R.bag_double_map[with_underscore] = v.id
	end
end

local job_flags = R.flags.job_flags
local job_index = R.flags.job_index

function R.get_current_equipment()
	local ret = windower.ffxi.get_items().equipment
	for k,v in pairs(ret) do
		for slotid, slot in pairs(res.slots) do
			if string.lower(k) == string.lower(slot.en) then
				ret[slotid] = v
			end
		end
	end
	return ret
end

function R.get_all_items()
	local bags = windower.ffxi.get_items()
	local ret = {}
	for bagName,bag in pairs(bags) do
		--if find(
		--	{
		--		"inventory",
		--		"wardrobe",
		--		"wardrobe2",
		--		"wardrobe3",
		--		"wardrobe4",
		--	}, bagName)
		--then
		--if (bagName == "inventory") or (bagName == "wardrobe") or (bagName == "wardrobe2") or (bagName == "wardrobe3") or (bagName == "wardrobe4") then
		--print("dbg 1")
		if type(bag) == "table" then
			--print("dbg 2")
			for _, item in pairs(bag) do
				--print("dbg 3")
				if type(item) == 'table' and item.id ~= nil and item.id > 0 then
					--print("dbg 4")
					if res.items[item.id] ~= nil
					--and (res.items[item.id].category == "Armor" or res.items[item.id].category == "Weapon")
					then
						--print("dbg 5")
						--print(res.items[item.id].en)
						--ret[item.id] = item
						--ret[item.id].storage = bagName
						
						local nextIndex = #ret + 1
						ret[nextIndex] = shallow_copy(item)
						ret[nextIndex].storage = bagName
						--print("ret[" .. nextIndex .. "] = " .. res.items[item.id].en)
					end
				end -- if valid item
			end -- for item in bag
		end -- if right type of inventory
	end -- for bags

	--print("dbg 6")
	--print("get_all_items() at " .. #ret .. " items before slips.")

	local slips_all = slips.get_player_items()
	for slip_id, slip_items in pairs(slips_all) do
		local slip_name = "slip " .. (find(slips.storages, slip_id) or "?")
		for _, itemid in pairs(slip_items) do
			table.insert(ret, 
			{
				id = itemid,
				storage = slip_name,
				slip = slip_id,
			})
		end
	end

	--print("get_all_items() returning " .. #ret .. " items.")
	return ret
end

function R.get_all_equipment()
	local ret = {}
	for id, item in pairs(R.get_all_items()) do
		if res.items[item.id] ~= nil
			and (res.items[item.id].category == "Armor" or res.items[item.id].category == "Weapon")
		then
			--ret[id] = item
			ret[#ret+1] = item
		--elseif res.items[item.id] ~= nil then
		--	print("Excluding " .. res.items[item.id].en)
		end
	end
	--print("get_all_equipment() returning " .. #ret .. " items.")
	return ret
end

function R.filter_is_equipment(items)
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

function R.filter_in_equippable_storage(items)
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

function R.get_equippable_equipment(job_optional, level_optional)
	local count = 0
	local bags = windower.ffxi.get_items()
	local player = Client.get_player()
	local job = string.upper(job_optional or player.main_job)
	local level = level_optional or player.jobs[job] or 0
	local ret = {}
	local num_added = 0

	-- categories are "Weapon", "Armor", "Usable", "General"

	local all_equipment = R.get_all_equipment()
	--print ("all_equipment = " .. tostring(all_equipment))
	for _, item in pairs(all_equipment) do
		local matching_inventory = 
			(Conf.SEARCH_ALL_STORAGES and (find(
				{
					"inventory",
					"wardrobe",
					"wardrobe2",
					"wardrobe3",
					"safe",
					"safe2",
					"locker",
					"storage",
					"case",
					"satchel",
					"slip 1",
					"slip 2",
					"slip 3",
					"slip 4",
					"slip 5",
					"slip 6",
					"slip 7",
					"slip 8",
					"slip 9",
					"slip 10",
					"slip 11",
					"slip 12",
					"slip 13",
					"slip 14",
					"slip 15",
					"slip 16",
					"slip 17",
					"slip 18",
					"slip 19",
					"slip 20",
					"slip 21",
					"slip 22",
					"slip 23",
					"slip 24",
					"slip 25",
					"slip 26",
					"slip 27",
					"slip 28",
				}, item.storage)))
			or (not Conf.SEARCH_ALL_STORAGES and find(
				{
					"inventory",
					"wardrobe",
					"wardrobe2",
					"wardrobe3",
				}, item.storage))
		if matching_inventory and R.can_equip(item, job, level, player) then
			table.insert(ret, shallow_copy(item))
		end
	end
	
	--print("get_equippable_equipment() returning " .. #ret .. " items.") -- .. debug.traceback())
	--print(ret)

	if true then return ret end
	-- TODO: Clean up code

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
							if R.can_equip(item, job, level, player) then
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
	return ret
end

function R.can_equip(item, job_optional, level_optional, player_optional)
	--things to check: race/gender, job, level
	-- TODO: Filter only category
	local player = player_optional or Client.get_player()
	local job = string.upper(job_optional or player.main_job)
	local job_level = level_optional or player.jobs[job] or 0
	local res_item = res.items[item.id]
	if res_item.category ~= "Weapon" and res_item.category ~= "Armor" then return false end

	if item ~= nil and item.id ~= nil and res.items[item.id] ~= nil then
		if not res_item.races[player.race] then return false end
		if not res_item.jobs[job_index[job]] then return false end
		--if player.main_job_level < res_item.level then return false end
		if job_level < res_item.level then return false end
		return true
	end
	return false
end

function R.dereference_set_ids(categorized_gear_list, indices)
	local ret = {}
	for slot,index in indices do
		ret[slot] = categorized_gear_list[slot][index].id
	end
	return ret
end

function R.get_equipment_slot_id_of_item(item)
	if item == nil or item.id == nil or res.items[item.id] == nil or res.items[item.id].slots == nil then return nil end
	for _, slot in pairs(resources.slots) do
		if res.items[item.id].slots[slot.id] then return slot.id end
	end
	return nil
end

function R.get_slot_name_of_item(item)
	return resources.slots[get_equipment_slot_id_of_item(item)].en
end





-- From topaz/src/modifier.h
-- cat mods-enum-cpp.txt | sed s/\\\ *\\\([A-Za-z0-9_]*\\\)\\\ *=\\\ *\\\([0-9]*\\\).*/\\\[\\\2\\\]=\\\"\\\1\\\",/ > modifiers.lua
-- will require slight editing at beginning and end of file
R.modifiers = require("modifiers")
-- two-way mapping for modifiers
R.modifiers = merge_right(R.modifiers, mirror(R.modifiers))
	--for k,v in pairs(R.modifiers) do
	--	R.modifiers[v] = k
	--end



local create_get_modifier_by_alias = require('modifier_aliases')
R.get_modifier_by_alias = create_get_modifier_by_alias(R.modifiers) -- State capture! Factory pattern!! PROGRAMMING!!!



-- From sql/item_mods.sql
-- OLD: cat item_mods.sql | sed s/[^0-9]*\\\([0-9]*\\\),\\\([0-9]*\\\),\\\([0-9-]*\\\).*/\{item_id=\\1,mod=\\2,value=\\3\},/ > item_mods_data.lua
-- cat item_mods.sql | sed s/[^0-9\\-]*\\\([0-9]*\\\),\\\([0-9]*\\\),\\\([0-9-]*\\\).*/\{item_id=\\1,mod=\\2,value=\\3\},/ > item_mods_data.lua
local item_mods_data = require("item_mods_data")




-- SELECT itemId,dmg,delay FROM item_weapon;
-- cat weapon_dmg_delay.csv | sed s/\\\([0-9]*\\\),\\\([0-9]*\\\),\\\([0-9]*\\\)/\\\{item_id=\\1,dmg=\\2,delay=\\3\\\},/ > weapon_dmg_delay.lua
local weapon_dmg_delay = require("weapon_dmg_delay")
--print("Adding weapon damage/delay to item mods")
--windower.add_to_chat(0, "Adding weapon damage/delay to item mods")
for _,weapon_info in pairs(weapon_dmg_delay) do
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

R.item_mods = {}
	-- convert relational database data to tables
	-- item_mods[item_id][mod_index] = amount
	for _,mod in pairs(item_mods_data) do
		R.item_mods[mod.item_id] = R.item_mods[mod.item_id] or {}
		R.item_mods[mod.item_id][mod.mod] = mod.value
	end

item_mods_data = nil




function R.apply_item_mods(mod_accum, item)
	if type(R.item_mods[item.id]) ~= "table" then return end
	for mod_id,mod_amount in pairs(R.item_mods[item.id]) do
		mod_accum[mod_id] = mod_accum[mod_id] or 0
		mod_accum[mod_id] = mod_accum[mod_id] + mod_amount
	end
end

function R.apply_set_mods(mod_accum, gear_set)
	for _, item in pairs(gear_set) do
		R.apply_item_mods(mod_accum, item)
	end
end

function R.apply_set_mods_by_index(mod_accum, gears, cur_indeces)
	local function get_slot(slot_name)
		return gears[slot_name][cur_indeces[R.flags.slot_index[slot_name]]]
	end
	for k,slot_obj in pairs(resources.slots) do
		local item = get_slot(slot_obj.en)
		if item ~= nil then
			R.apply_item_mods(mod_accum, item)
		end
	end
end

function R.get_modifier_id(alias)
	return R.modifiers[R.get_modifier_by_alias(alias)]
end

function R.get_item_name(item)
	local item_id
	if type(item) == "number" then
		item_id = item
	elseif (type(item) == "table" and item.id ~= nil) then
		item_id = item.id
	else
		return "?"
	end
	return (res.items[item_id] and res.items[item_id].en) or "?"
end

-- TODO: I don't think there's anything windower specific in this one.
--		Maybe have a generic_item_utils.lua and do a table merge into Client.item_utils
function R.calc_total_mods(gear_list, indices)
	local total_mods = {}
	function total_mods.by_name(alias, default_value)
		return total_mods[R.get_modifier_id(alias)] or default_value or 0
	end
	R.apply_set_mods_by_index(total_mods, gear_list, indices)
	return total_mods
end

function R.create_indexed_set(categorized_gear_list_param, indices_param, purpose_checked_against_param, apparent_utility_results_param)
	local indexed_set =
	{
		categorized_gear_list = categorized_gear_list_param,
		purpose_checked_against = purpose_checked_against_param,
		apparent_utility_results = apparent_utility_results_param,
		indices = indices_param,
	}

	-- pre-calculate the total modifiers
	indexed_set.total_mods = Client.item_utils.calc_total_mods(categorized_gear_list_param, indices_param)

	-- dereference() returns a table of { [slot_id] = {item} }
	indexed_set.dereference = function()
		local dereferenced_set = {}
		for sloti, index_into_gear_list in pairs(indexed_set.indices) do
			--print("r[" .. sloti .. "] = " .. Client.item_utils.get_item_name(set_struct.categorized_gear_list[sloti][index_into_gear_list]))
			dereferenced_set[sloti] = indexed_set.categorized_gear_list[sloti][index_into_gear_list]
		end
		return dereferenced_set
	end

	-- get_slot_item() returns the item, notably including .id
	function indexed_set.get_slot_item(slot_name)
		local item
		pcall(function()
			item = indexed_set.categorized_gear_list[slot_name][indexed_set.indices[Client.item_utils.flags.slot_index[slot_name]]]
		end)
		if (item == nil or item.id == nil) then return {} end
		return item
	end

	-- get_slot_res() returns the windower resource for the item in a particular slot
	function indexed_set.get_slot_res(slot_name)
		local item
		pcall(function()
			item = indexed_set.categorized_gear_list[slot_name][indexed_set.indices[Client.item_utils.flags.slot_index[slot_name]]]
		end)
		if (item == nil or item.id == nil) then return {} end
		return resources.items[item.id] or {}
	end
	return indexed_set
end

function R.find_item(id, equipment_list, skip_first) -- Returns item_object, accessible_boolean
	local seen_first = false
	if equipment_list == nil then
		equipment_list = R.get_all_items()
	end
	for i = 1, #equipment_list do
		if equipment_list[i].id == id then
			local accessible = (find({"inventory", "sack", "satchel", "case", "wardrobe", "wardrobe2", "wardrobe3", "wardrobe4"}, equipment_list[i].storage) ~= nil)
			if skip_first and not seen_first then
				seen_first = true
			elseif skip_first and seen_first then
				return equipment_list[i], accessible
			else
				return equipment_list[i], accessible
			end
		end
	end
end

function R.is_transferrable(item)
	return (find({"inventory", "sack", "satchel", "case", "wardrobe", "wardrobe2", "wardrobe3", "wardrobe4"}, item.storage) ~= nil)
end

function R.get_free_space(bag)
	local inv = windower.ffxi.get_items()
	return inv["max_" .. bag] - inv["count_" .. bag]
end

function R.find_first_unequippable(itemid)
	local function search(bag)
		for i,item in ipairs(bag) do
			if item.id ==  itemid then return item, i end
		end
	end

	local r
	r = search(windower.get_items("sack"))
	if r then
		r.storage = "sack"
		return r
	end
	bag = search(windower.get_items("satchel"))
	if r then
		r.storage = "satchel"
		return r
	end
	bag = search(windower.get_items("case"))
	if r then
		r.storage = "case"
		return r
	end
	bag = search(windower.get_items("safe"))
	if r then
		r.storage = "safe"
		return r
	end
	bag = search(windower.get_items("safe2"))
	if r then
		r.storage = "safe2"
		return r
	end
	bag = search(windower.get_items("locker"))
	if r then
		r.storage = "locker"
		return r
	end
	bag = search(windower.get_items("storage"))
	if r then
		r.storage = "storage"
		return r
	end

	local slips_all = slips.get_player_items()
	for slip_id, slip_items in pairs(slips_all) do
		local slip_name = "slip " .. (find(slips.storages, slip_id) or "?")
		for _, slip_itemid in pairs(slip_items) do
			if slip_itemid == itemid then
				return {
					id = itemid,
					storage = slip_name,
					slip = slip_id,
				}
			end
		end
	end
end


--[[
function R.remap_items(optional_job_string_or_categorized_gear_list_table)
	local arg = optional_job_string_or_categorized_gear_list_table
	local itemid
	local all_equipment = R.get_all_equipment()
	local accessible_equipment = R.get_equippable_equipment()

	if type(arg) == "table" then
		for sloti = 0, 15 do
			for i,item in pairs(arg[sloti]) do
				if type(item) == "number" then 
					itemid = item
				elseif type(item) == "table" then
					itemid = item.id
				else itemid = 0
				end

			end -- for item
		end -- for slot
	elseif type(arg) == "string" then
	elseif arg == nil then
	end
end
]]


return R
