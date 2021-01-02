require('util')

local R = {
	flags = require('flags')
}
res = require('resources')

local job_flags = R.flags.job_flags
local job_index = R.flags.job_index

function R.get_all_items()
	local bags = Client.get_items()
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

function R.get_all_equipment()
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

function R.get_equippable_equipment()
	--notice("Boop")
	--notice("p1=" .. p1 .. "  p2=" .. p2)
	local count = 0
	local bags = windower.ffxi.get_items()
	local player = Client.get_player()
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
							if R.can_equip(item, player) then
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

function R.can_equip(item, player_optional)
	--things to check: race/gender, job, level
	-- TODO: Filter only category
	local player = player_optional or Client.get_player()
	local res_item = res.items[item.id]
	if res_item.category ~= "Weapon" and res_item.category ~= "Armor" then return false end

	if item ~= nil and item.id ~= nil and res.items[item.id] ~= nil then
		if not res_item.races[player.race] then return false end
		if not res_item.jobs[job_index[player.main_job]] then return false end
		if player.main_job_level < res_item.level then return false end
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
	for k,v in pairs(R.modifiers) do
		R.modifiers[v] = k
	end



local create_get_modifier_by_alias = require('modifier_aliases')
R.get_modifier_by_alias = create_get_modifier_by_alias(R.modifiers) -- State capture! Factory pattern!! PROGRAMMING!!!



-- From sql/item_mods.sql
-- OLD: cat item_mods.sql | sed s/[^0-9]*\\\([0-9]*\\\),\\\([0-9]*\\\),\\\([0-9-]*\\\).*/\{item_id=\\1,mod=\\2,value=\\3\},/ > item_mods_data.lua
-- cat item_mods.sql | sed s/[^0-9\\-]*\\\([0-9]*\\\),\\\([0-9]*\\\),\\\([0-9-]*\\\).*/\{item_id=\\1,mod=\\2,value=\\3\},/ > item_mods_data.lua
local item_mods_data = require("item_mods_data")

R.item_mods = {}
	-- convert relational database data to tables
	-- item_mods[item_id][mod_index] = amount
	for _,mod in pairs(item_mods_data) do
		R.item_mods[mod.item_id] = R.item_mods[mod.item_id] or {}
		R.item_mods[mod.item_id][mod.mod] = mod.value
	end



-- SELECT itemId,dmg,delay FROM item_weapon;
-- cat weapon_dmg_delay.csv | sed s/\\\([0-9]*\\\),\\\([0-9]*\\\),\\\([0-9]*\\\)/\\\{item_id=\\1,dmg=\\2,delay=\\3\\\},/ > weapon_dmg_delay.lua
local weapon_dmg_delay = require("weapon_dmg_delay")

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

item_mods_data = nil




function R.apply_item_mods(mod_accum, item)
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

return R