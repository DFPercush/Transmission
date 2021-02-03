-- Utility functions

-- Windower resources
--local res = require("resources")
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

function tcount(some_table, optional_predicate_v_k)
	local ret = 0
	-- leaving this out might help find some other problems
	--if type(some_table) ~= "table" then return 0 end
	if type(some_table) ~= "table" then return 0 end
	for k,v in pairs(some_table) do
		if type(v) ~= "function" then
			if (optional_predicate_v_k == nil) or (optional_predicate_v_k(v,k)) then
				ret = ret + 1
			end
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

function item_name(item)
	local id
	if type(item) == "number" then id = item
	else id = item.id
	end
	if id == nil then return "?" end
	return res.items[id].en
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
		if #x == tcount(x) then
			out = out .. "{"
			for i = 1, #x do
				out = out .. tostring(x[i]) .. ","
			end
			out = out .. "}"
			--if depth > 1 then out = out .. "," end
		else
			out = out .. "\n" .. padding .. "{\n"
			for k, v in pairs(x) do
				if type(k) == "number" then
					out = out .. padding .. pad_per_level .. "[" .. tostring(k, depth+1) .. "] = " .. tostring(v, depth+1) .. "\n"
				else
					out = out .. padding .. pad_per_level .. tostring(k, depth+1) .. " = " .. tostring(v, depth+1) .. "\n"
				end
			end
			out = out .. padding .. "}"
			--if depth > 1 then out = out .. "," end
		end
		return out
	else
		return old_tostring(x)
	end
end

-- TODO: This interacts with the game, probably shouldn't be in this file
console_print = print
function print_somewhere(stuff)
	if Client and Client.add_to_chat then
		Client.add_to_chat(204, stuff)
	else
		console_print(stuff)
	end
end

function print(...)
	local nargs = select("#", ...)
	local out = ""
	for i=1,nargs do
		local thing = select(i, ...)
		local msg = tostring(thing)
		local L = string.len(msg)
		if (L <= 0) then return end
		for i = 1, L, 1 do
			local c = string.sub(msg, i, i)
			--if (msg[i] == "\n") then
			if c == "\n" then
				if string.len(out) > 0 then
				print_somewhere(out)
				end
				out = ""
			else
				out = out .. c --tostring(msg[i])
			end -- if newline
		end -- for char in string
	end -- for arg
	print_somewhere(out)
end

function stale_function()
	error("Tried to call a stale function in serialized data. Object was not reconstructed properly.")
end

function serialize(x, depth)
	local pad_per_level = "  " -- "  "
	local out = ""
	local padding = ""
	if (depth == nil) then
		--print("depth = nil at " .. debug.traceback())
		depth = 1
	--elseif depth == 1 then
	--	print("depth = nil at " .. debug.traceback())
	else
		for i = 1, depth - 1, 1 do
			padding = padding .. pad_per_level
		end
	end
	local ty = type(x)
	if ty == "nil" then
		return "nil"
	elseif ty == "number" then
		return old_tostring(x)
	elseif ty == "string" then
		return '\"' .. x .. '\"'
	elseif ty == "function" then
		--error("Can not serialize a function")
		return "stale_function"
	--elseif ty == "boolean" then
	--	if x then
	--		return "true"
	--	else
	--		return "false"
	--	end
	elseif ty == "table" then
		-- if (x == {}) then  -- references!
		if (is_empty(x)) then
			return "{}"
		end
		if false then
		elseif #x == tcount(x) then
			out = out .. "{"
			for i = 1, #x do
				out = out .. serialize(x[i], depth+1) .. ","
			end
			out = out .. "}"
			--if depth > 1 then out = out .. "," end
		elseif #x + 1 == tcount(x) and x[0] ~= nil then
			out = out .. "{"
			for i = 1, #x do
				out = out .. serialize(x[i], depth+1) .. ","
			end
			out = out .. "[0]=" .. serialize(x[0], depth+1) .. ","
			out = out .. "}"
			--if depth > 1 then out = out .. "," end
		else
			out = out .. "\n" .. padding .. "{\n"
			for k, v in pairs(x) do
				local kstr
				if type(k) == "number" then
					kstr = "[" .. k .. "]"
					--out = out .. padding .. pad_per_level .. "[" .. k .. "] = " .. serialize(v, depth+1) .. "\n"
				elseif type(k) == "string" then
					--kstr = k "\"" .. k .. "\""
					kstr = k
					--out = out .. padding .. pad_per_level .. k .. " = " .. serialize(v, depth+1) .. "\n"
				else
					kstr = serialize(k, depth+1)
					--out = out .. padding .. pad_per_level .. serialize(k, depth+1) .. " = " .. serialize(v, depth+1) .. "\n"
				end
				out = out .. padding .. pad_per_level .. kstr .. "=" .. serialize(v, depth+1) .. ",\n"
			end
			out = out .. padding .. "}"
			--if depth > 1 then out = out .. "," end
		end
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

function round(num, numDecimalPlaces)
	local mult = 10^(numDecimalPlaces or 0)
	return math.floor(num * mult + 0.5) / mult
end

function find(haystack, needle)
	for k,v in pairs(haystack) do
		if v == needle then
			return k
		end
	end
	return nil
end

function mirror(kv_to_vk)
	if type(kv_to_vk) == "table" then
		local t = {}
		for k,v in pairs(kv_to_vk) do
			t[v] = k
		end
		return t
	elseif type(kv_to_vk) == "string" then
		local s = ""
		for i = string.len(kv_to_vk), 1, -1 do
			s = s .. kv_to_vk[i]
		end
		return s
	end
end

function insert_unique(t, v, optional_equals_function)
	for i = 1, #t do
		if optional_equals_function and optional_equals_function(t[i], v) then return end
		if t[i] == v then return end
	end
	table.insert(t, v)
end

function is_empty(t)
	return (tcount(t) == 0)
end

function deep_copy(t, predicate_takes_args_value_comma_key)
	local pr = predicate_takes_args_value_comma_key
	if type(t) ~= "table" then
		return t
		--if predicate_takes_args_value_comma_key(t) then
		--	return t
		--else
		--	return nil
		--end
	end
	local r = {}
	for k,v in pairs(t) do
		if (pr == nil) or (pr(v,k)) then
			r[deep_copy(k, pr)] = deep_copy(v, pr)
		end
	end
	return r
end

function keys(t)
	local ret = {}
	for k,v in pairs(t) do
		ret[#ret+1] = k
	end
	return ret
end

function map(t, func_v_k)
	local ret = {}
	for k,v in pairs(t) do
		local v2, k2 = func_v_k(v,k)
		if k2 == nil then
			k2 = k
		end
		if v2 ~= nil then
			ret[k2] = v2
		end
	end
	return ret
end

function filter(t, f)
	local ret = {}
	for k,v in pairs(t) do
		if f(v) then ret[k] = v end
	end
	return ret
end

function reduce(t, init_value, func_v_k_accum)
	local ret = init_value
	for k,v in pairs(t) do
		ret = func_v_k_accum(v,k,ret)
	end
	return ret
end

function quick_trace(separator)
	separator = separator or ""
	local f
	local maxlevel = 1
	local r = ""
	repeat
		maxlevel = maxlevel + 1
		f = debug.getinfo(maxlevel, "Sln")
	until not f
	for level = maxlevel-1, 2, -1 do
		f = debug.getinfo(level, "Snl")
		if not f then break end
		if f.name then
			r = r .. f.name .. "():" .. f.currentline .. separator
		else
			r = r .. (f.short_src or "?") .. ":" .. f.currentline .. separator
		end
	end
	return r
end
