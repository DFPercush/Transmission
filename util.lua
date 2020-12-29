-- Utility functions

-- Windower resources
local res = require("resources")
local flags = require("flags")
local modifiers = require("modifiers")

-- Typical call:  if hasbit(x, bit(3)) then ...
function hasbit(x, p) return x % (p + p) >= p end
function setbit(x, p) return hasbit(x, p) and x or x + p end
function clearbit(x, p) return hasbit(x, p) and x - p or x end
function testflag(set, flag) return set % (2*flag) >= flag end
testbit = testflag
function setflag(set, flag) if set % (2*flag) >= flag then return set end return set + flag end
function clrflag(set, flag) if set % (2*flag) >= flag then return set - flag end return set end

function merge_left(...)
	local r = {}
	local num_tables = select("#", ...)
	for iTable = 1,num_tables do
		for k,v in pairs(select(iTable, ...)) do r[k] = v end
	end
	return r
end

function merge_right(...)
	local r = {}
	local num_tables = select("#", ...)
	for iTable = num_tables,1,-1 do
		for k,v in pairs(select(iTable, ...)) do r[k] = v end
	end
	return r
end

function append(t1, t2)
	for k,v in pairs(t2) do
		t1[#t1+1] = v
	end
	return t1
end

function tcount(some_table)
	local ret = 0
	-- leaving this out might help find some other problems
	--if type(some_table) ~= "table" then return 0 end
	for k,v in pairs(some_table) do
		if type(v) ~= "function" then
			ret = ret + 1
		end
	end
	return ret
end

function shallow_copy(t)
	local ret = {}
	for k,v in pairs(t) do
		ret[k] = v
	end
	return ret
end

function reverse_map(t)
	ret = {}
	for k,v in pairs(t) do
		ret[v] = k
	end
	return ret
end

function get_player()
	return merge_right(windower.ffxi.get_player(), windower.ffxi.get_mob_by_target("me"))
end

function item_name(item)
	local id
	if type(item) == "number" then id = item
	else id = item.id
	end
	if id == nil then return "?" end
	return res.items[id].en
end


console_print = print
function print(msg)
	msg = tostring(msg)
	local L = string.len(msg)
	out = ""
	for i = 1, L, 1 do
		if (msg[i] == "\n") then
			windower.add_to_chat(204, out)
			out = ""
		else
			out = out .. msg[i]
		end
	end
	windower.add_to_chat(204, out)
end

old_tostring = tostring
function tostring(x, depth)
	local pad_per_level = "  "
	local out = ""
	local padding = ""
	if (depth == nil) then
		depth = 1
	else
		for i = 1, depth - 1, 1 do
			padding = padding .. pad_per_level
		end
	end
	if (type(x) == type({})) then
		if (x == {}) then
			return "{}"
		end
		out = out .. "\n" .. padding .. "{\n"
		for k, v in pairs(x) do
			out = out .. padding .. pad_per_level .. tostring(k, depth+1) .. " = " .. tostring(v, depth+1) .. "\n"
		end
		out = out .. padding .. "}"
		return out
	else
		return old_tostring(x)
	end
end

function forcenumber(x, default_value)
	local ret = tonumber(x)
	if default_value == nil then default_value = 0 end
	if ret == nil then ret = default_value end
	return ret
end

function get_dual_wield_level(player)
	player = player or get_player()
	if player.main_job == "NIN" then
		if player.main_job_level >= 85 then return 5
		elseif player.main_job_level >= 65 then return 4
		elseif player.main_job_level >= 45 then return 3
		elseif player.main_job_level >= 25 then return 2
		elseif player.main_job_level >= 10 then return 1
		end
	elseif player.main_job == "DNC" then
		if player.main_job_level >= 80 then return 4
		elseif player.main_job_level >= 60 then return 3
		elseif player.main_job_level >= 40 then return 2
		elseif player.main_job_level >= 20 then return 1
		end
	elseif player.main_job == "THF" then
		if (player.main_job_level >= 99) and ((player.job_points.thf.jp_spent + player.job_points.thf.job_points) >= 550) then return 4
		elseif (player.main_job_level >= 98) then return 3
		elseif (player.main_job_level >= 87) then return 2
		elseif (player.main_job_level >= 83) then return 1
		end
	elseif player.main_job == "BLU" then
		if (player.main_job_level >= 99) and ((player.job_points.blue.jp_spent + player.job_points.blu.job_points) >= 100) then return 4
		elseif player.main_job_level >= 99 then return 3
		elseif player.main_job_level >= 89 then return 2
		elseif player.main_job_level >= 80 then return 1
		end
	end

	if player.sub_job == "NIN" then
		if player.sub_job_level >= 85 then return 5
		elseif player.sub_job_level >= 65 then return 4
		elseif player.sub_job_level >= 45 then return 3
		elseif player.sub_job_level >= 25 then return 2
		elseif player.sub_job_level >= 10 then return 1
		end
	elseif player.sub_job == "DNC" then
		if player.sub_job_level >= 80 then return 4
		elseif player.sub_job_level >= 60 then return 3
		elseif player.sub_job_level >= 40 then return 2
		elseif player.sub_job_level >= 20 then return 1
		end
	elseif player.sub_job == "THF" then
		if (player.sub_job_level >= 98) then return 3
		elseif (player.sub_job_level >= 87) then return 2
		elseif (player.sub_job_level >= 83) then return 1
		end
	elseif player.sub_job == "BLU" then
		if player.sub_job_level >= 99 then return 3
		elseif player.sub_job_level >= 89 then return 2
		elseif player.sub_job_level >= 80 then return 1
		end
	end
	return 0
end

function get_martial_arts_level(player)
	player = player or get_player()
	if player.main_job == "MNK" then
		if player.main_job_level >= 82 then return 7
		elseif player.main_job_level >= 75 then return 6
		elseif player.main_job_level >= 61 then return 5
		elseif player.main_job_level >= 46 then return 4
		elseif player.main_job_level >= 31 then return 3
		elseif player.main_job_level >= 16 then return 2
		else return 1
		end
	elseif player.main_job == "PUP" then
		if player.main_job_level >= 97 then return 5
		elseif player.main_job_level >= 86 then return 4
		elseif player.main_job_level >= 75 then return 3
		elseif player.main_job_level >= 50 then return 2
		elseif player.main_job_level >= 25 then return 1
		end
	end
	if player.sub_job == "MNK" then
		if player.sub_job_level >= 82 then return 7
		elseif player.sub_job_level >= 75 then return 6
		elseif player.sub_job_level >= 61 then return 5
		elseif player.sub_job_level >= 46 then return 4
		elseif player.sub_job_level >= 31 then return 3
		elseif player.sub_job_level >= 16 then return 2
		else return 1
		end
	elseif player.sub_job == "PUP" then
		if player.sub_job_level >= 97 then return 5
		elseif player.sub_job_level >= 86 then return 4
		elseif player.sub_job_level >= 75 then return 3
		elseif player.sub_job_level >= 50 then return 2
		elseif player.sub_job_level >= 25 then return 1
		end
	end    
	return 0
end

function max(...)
	local len = select("#", ...)
	local ret = select(1, ...)
	for i = 1, len do
		local n = select(i, ...)
		if type(n) == 'number' and n > ret then ret = n end
	end
	return ret
end

function min(...)
	local len = select("#", ...)
	local ret = select(1, ...)
	for i = 1, len do
		local n = select(i, ...)
		if type(n) == 'number' and n < ret then ret = n end
	end
	return ret
end

function apply_item_mods(mod_accum, item)
	for mod_id,mod_amount in pairs(item_mods[item.id]) do
		mod_accum[mod_id] = mod_accum[mod_id] or 0
		mod_accum[mod_id] = mod_accum[mod_id] + mod_amount
	end
end

function apply_set_mods(mod_accum, gear_set)
	for _, item in pairs(gear_set) do
		apply_item_mods(mod_accum, item)
	end
end

function apply_set_mods_by_index(mod_accum, gears, cur_indeces)
	local function get_slot(slot_name)
		return gears[slot_name][cur_indeces[flags.slot_index[slot_name]]]
	end
	for k,slot_obj in pairs(resources.slots) do
		local item = get_slot(slot_obj.en)
		if item ~= nil then
			apply_item_mods(mod_accum, item)
		end
	end
end

function get_modifier_id(alias)
	return modifiers[get_modifier_by_alias(alias)]
end

-- multi_for_next:
--  Increments a list of indexes or values and carries over when one of them exceeds max.
--  It's like a state machine for a multi-dimensional for loop
function multi_dimension_next(cur, min, max) -- returns true if can keep going, false when done. while next_carry(cur,max) do ... end
	-- skipping bounds validation for speed
	--if #cur > #max then
	--	for i = #max + 1, #cur do max[i] = 0 end
	--end
	cur[1] = cur[1] + 1
	--if (cur[1] <= max[1]) then return true end
	local c = 1 -- carry
	while (c <= #max) and (cur[c] >= max[c]) do
		--if c >= #max then return false end -- overflow, we're done
		--print("c > #max ---> " .. c .. " > " .. #max .. "  ?")
		--if c > #max then
		--	print("Overflow, done")
		--	return false -- overflow, we're done
		--end
		--print("c(1) = " .. c .. " and max[" .. c .. "] = " .. max[c])
		if cur[c] > max[c] then
			cur[c] = min[c]
			--print("c(2) = " .. c)
			if (c < #max) then
				cur[c + 1] = cur[c + 1] + 1
			end
			c = c + 1
			--print("c(3) = " .. c)
			if c > #max then
				--print("Overflow, done")
				return false -- overflow, we're done
			end
		else
			break
		end
	end
	return true
end

function zero_based_array_tostring_horizontal(a)
	if a == nil then return "nil" end
	local ret = "{"
	for i = 0, #a do
		if i > 0 then
			ret = ret .. ", "
		end
		ret = ret .. a[i]
	end
	ret = ret .. "}"
	return ret
end

function array_tostring_horizontal(a)
	if a == nil then return "nil" end
	local ret = "{"
	if (a[0] ~= nil) then ret = ret .. "[0]=" .. tostring(a[0]) ..", " end
	for i = 1, #a do
		if i > 1 then
			ret = ret .. ", "
		end
		ret = ret .. tostring(a[i])
	end
	ret = ret .. "}"
	return ret
end

local OCCASIONALLY_ATTACKS_AVERAGE = {
	[1] = 1,
	[2] = 1.44991,
	[3] = 1.90021,
	[4] = 2.49992,
	[5] = 3.09979,
	[6] = 3.5003,
	[7] = 3.79998,
	[8] = 3.81987,
}
function get_average_swings(gears, cur_indeces, mods, player)
	function get_slot(slot_name)
		return gears[slot_name][cur_indeces[flags.slot_index[slot_name]+1]] or {}
	end
	local swings = 1
	-- occasionally attacks x times
	-- MAX_SWINGS  battleutils -> getHitCount() (max 8)
	local max_swings = 1
	local main_hits = MULTI_HIT_WEAPONS[get_slot("Main").id or 0]
	if main_hits ~= nil then max_swings = max_swings + main_hits end
	local sub_hits = MULTI_HIT_WEAPONS[get_slot("Sub").id]
	if (sub_hits ~= nil) then max_swings = max_swings + sub_hits end
	if mods.MAX_SWINGS ~= nil then max_swings = max_swings + mods.MAX_SWINGS end
	swings = OCCASIONALLY_ATTACKS_AVERAGE[min(8, mods.MAX_SWINGS)]
	swings = swings + (forcenumber(mods.DOUBLE_ATTACK) * 1 / 100)
	swings = swings + (forcenumber(mods.TRIPLE_ATTACK) * 2 / 100)
	swings = swings + (forcenumber(mods.QUAD_ATTACK) * 3 / 100)
	swings = swings + (forcenumber(mods.MYTHIC_OCC_ATT_TWICE) * 1 / 100)
	swings = swings + (forcenumber(mods.MYTHIC_OCC_ATT_THRICE) * 2 / 100)

	-- double attack
	if ((player.main_job == "WAR" and player.main_job_level >= 25) or (player.sub_job == "WAR" and player.sub_job_level >= 25)) then
		swings = swings + 0.1
	elseif ((player.main_job == "BLU" and player.main_job_level >= 80)) then
		swings = swings + 0.07
	end

	-- triple attack
	if ((player.main_job == "THF" and player.main_job_level >= 55) or (player.main_job == "BLU" and player.main_job_level >= 96)) then
		swings = swings + 0.1 -- 5% chance x2 additional attacks
	end
	-- TODO: triple attack II rate?

	if swings > 8 then swings = 8 end
	return swings
end

function feq(a, b, threshold_optional)
	threshold_optional = (threshold_optional) or (0.001 * b)
	if a < b - threshold_optional then return false
	elseif a > b + threshold_optional then return false
	else return true
	end
end

function filter_array_in_place(t, predicate)
	function default_predicate(x)
		return x ~= nil
	end
	if predicate == nil then predicate = default_predicate end
	--predicate = predicate or default_predicate
	--local read_from = 1
	local write_to = 1
	local len = #t
	--print("filter_array_in_place(): len = " .. len)
	for read_from = 1, len do
		if predicate(t[read_from]) then
			--print("[" .. read_from .. "]" .. " -> [" .. write_to .. "]")
			t[write_to] = t[read_from]
			write_to = write_to + 1
		else
			--print("skip [" .. read_from .. "]")
		end
	end
	--print("[" .. (write_to) .. "-" .. len .. "] <- nil")
	--for i = write_to + 1, len do
	for i = write_to, len do
		t[i] = nil
	end
end

function get_equipment_slot_id_of_item(item)
	if item == nil or item.id == nil or res.items[item.id] == nil or res.items[item.id].slots == nil then return nil end
	for _, slot in pairs(resources.slots) do
		if res.items[item.id].slots[slot.id] then return slot.id end
	end
	return nil
end

function get_slot_name_of_item(item)
	return resources.slots[get_equipment_slot_id_of_item(item)].en
end

function teq(t1, t2)
	-- tables equal? (contents, not references)
	for k,v in pairs(t1) do
		if type(t1[k]) ~= type(t2[k]) then return false end
		if type(t1[k]) == "table" then
			if not teq(t1[k], t2[k]) then return false end
		else
			if t1[k] ~= t2[k] then return false end
		end
	end
	return true
end

