-- Utility functions

-- Windower resources
local res = require("resources")

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
	for k,v in pairs(some_table) do ret = ret + 1 end
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
	for i in 1, len do
		local n = select(i, ...)
		if type(n) == 'number' and n > ret then ret = n end
	end
	return ret
end

function min(...)
	local len = select("#", ...)
	local ret = select(1, ...)
	for i in 1, len do
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
	mod_accum = mod_accum or {}
	for _, item in pairs(gear_set) do
		apply_item_mods(mod_accum, item)
	end
end

function get_modifier_id(alias)
	return modifiers[get_modifier_by_alias(alias)]
end
