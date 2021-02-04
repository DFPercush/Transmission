--[[

Transmission

An FFXI "gear shifting" addon that automatically finds and optimizes
equipment for various purposes with minimal end user scripting.

By DFPercush and Silver_Skree

]]

_addon.name	   = 'Transmission'
_addon.author  = 'DFPercush'
_addon.version = '0.0.1'
_addon.commands = {'tm', 'transmission'}

require("data/settings")


print("Lua version " .. _VERSION)

--------------------------------------
--   Universally required globals   --
--------------------------------------

-- Override lua's default error handling to provide a stack trace.
lua_pcall = pcall
pcall = function(fn, ...)
	local co = coroutine.create(fn)
	local ok, ret = coroutine.resume(co, ...)
	if not ok then
		local stack_depth = 0
		while debug.getinfo(co, stack_depth + 3) do
			stack_depth = stack_depth + 1
		end
		while debug.getinfo(stack_depth + 3) do
			stack_depth = stack_depth + 1
		end
		ret = ret .. "\n" .. "Call depth: " .. stack_depth .. ", " .. debug.traceback(co) .. debug.traceback():sub(16)
	end
	coroutine.close(co)
	return ok, ret

	-- Only works in lua version > 5.2
	--return xpcall(fn, debug.traceback, ...)
end

__OUTSTANDING_COROUTINES__ = {}
function schedule(f,t)
	local id
	local function wrapper()
		local ret = f()
		coroutine.close(id)
		--__OUTSTANDING_COROUTINES__[id] = nil
		local i = find(__OUTSTANDING_COROUTINES__, id)
		if i > 0 then
			__OUTSTANDING_COROUTINES__[i] = nil
		end
		return ret
	end
	--id = coroutine.schedule(f,t)
	id = coroutine.schedule(wrapper,t)
	table.insert(__OUTSTANDING_COROUTINES__, id)
end


----------------------
--   Dependencies   --
----------------------

-- Abstraction layer
require('client')

-- Would like to clump this with the schedule function, but it has to come after client
Client.register_event('unload',function ()
	for i, coroutine_id in pairs(__OUTSTANDING_COROUTINES__) do
		coroutine.close(coroutine_id)
	end
end)

PURPOSES = require("purposes") -- Depends on global Client; require client first
local rolling_average = require "rolling_average"

-- Client (windower) components
-- TODO: Move to the client module...?

local res = Client.resources
resources = res



-- Third party libraries
--local Promise = require("deferred") -- Uses recursion to resolve and overflows the stack, not suitable for this application
Promise = require("promise")  -- my own thing

-- This addon
require('util')
--require('heuristics')
require('generate_useful_combinations_v1')
--local slot_flags = flags.slot_flags
require("modifier_aliases")
require("multi_hit_weapons")
require("react_to_next")
local Err = require("errors")

require('gear_continuum')

require('select_gear')





--===========●●●●●●●●●●●●●●● ★ ★ ★ ●●●●●●●●●●●●●●●●●===========--
--====●●●●●●              Ｍ　Ａ　Ｉ　Ｎ                ●●●●●●====--
--===========●●●●●●●●●●●●●●● ★ ★ ★ ●●●●●●●●●●●●●●●●●===========--





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



function peep()
	print("   ---=== Peep ===---   ")
	local target = Client.get_target()
	print(target)
end



function build_auto_attack()
	--local p = Promise.new():next(function() print("Promise resolved") end)
	--coroutine.schedule(function() p:resolve() end, .1)
	--if true then return end
	local purpose = PURPOSES.auto_attack
	local ret = async_build_gear_continuum('auto_attack'):next(
		function(result)
			print(" ------- DING, FRIES ARE DONE -------")
			print("result is a " .. type(result)) -- .. " : " .. tostring(result))
			if type(result) == "table" then
				print(tcount(result) .. " entries")
			end
			-- TODO: Character name, job, level, purpose etc
			local player = Client.get_player()
			if not Client.system.dir_exists(Client.addon_path .. "gear_continuum_plots") then
				Client.system.create_dir(Client.addon_path .. "gear_continuum_plots")
			end
			local base_file_name = Client.addon_path .. "gear_continuum_plots/" .. player.name .. "_" .. player.main_job .. player.main_job_level .. player.sub_job .. player.sub_job_level .. purpose.name
			local csv = io.open(base_file_name .. ".csv", "w")
			local obj = io.open(base_file_name .. ".obj", "w")
			-- TODO: There may not be 3 dimensions, maybe more, maybe less
			-- Start a new 3d object
			obj:write("o " .. base_file_name .. "\n")
			-- CSV header
			for d=1,#(purpose.dimension_names) do
				if d ~= 1 then csv:write(",") end
				csv:write(purpose.dimension_names[d])
			end
			for k,v in pairs(result) do
				--print(get_gear_set_string(v.categorized_gear_list, v.indices) .. " : " .. array_tostring_horizontal(v.apparent_utility_results))
				local csv_line = ""
				local obj_line = "v "
				for iCoord = 1,#(v.apparent_utility_results) do
					if iCoord > 1 then
						csv_line = csv_line .. ","
						obj_line = obj_line .. " "
					end
					csv_line = csv_line .. v.apparent_utility_results[iCoord]
					obj_line = obj_line .. v.apparent_utility_results[iCoord]
				end
				csv_line = csv_line .. "\n"
				csv:write(csv_line)
				obj_line = obj_line .. "\n"
				obj:write(obj_line)
			end
			obj:close()
			csv:close()
			return result
		end
	):catch(function (why)
		error("Calculation interrupted: " .. tostring(why))
	end)
	return ret, 0 -- trash to avoid tail call
end

local function rebuild(args)
	local job, level, notice_str
	notice_str = "Building"
	--print("rebuild() args = " .. tostring(args))
	if type(args[2]) == "string" then
		job = string.upper(args[2])
		notice_str = notice_str .. " " .. job
	end
	if type(args[3]) ~= nil then
		level = tonumber(args[3]) or Client.get_player().jobs[job] or 0
		notice_str = notice_str .. level
	elseif job ~= nil then
		level = Client.get_player().jobs[job]
		notice_str = notice_str .. level
	end
	if Conf.showmsg.REBUILD_START then
		notice(notice_str .. "...")
	end
	local when_finished

	-- Test to find a specific point of failure
	local test_purposes =
	{
		auto_attack = PURPOSES.auto_attack,
		--MND = PURPOSES.MND,
		--INT = PURPOSES.INT,
		--GARDENING_WILT_BONUS = PURPOSES.GARDENING_WILT_BONUS,
		--LIGHTDEF = PURPOSES.LIGHTDEF,
		--LIGHT_ARTS_SKILL = PURPOSES.LIGHT_ARTS_SKILL,
		--LIGHT_ARTS_EFFECT =  PURPOSES.LIGHT_ARTS_EFFECT,
		--LIGHT_ARTS_REGEN = PURPOSES.LIGHT_ARTS_REGEN,
	}
	local P = test_purposes
	--local P =  PURPOSES

	if level ~= nil then
		when_finished = async_rebuild_gear_cache_for_job(P, job, level)
	else
		-- TODO: Can pass { JOB = level, ...}
		when_finished = async_rebuild_gear_cache_for_multiple_jobs(P)
	end
	when_finished:next(
		function(count)
			--print("SAVING GEAR CACHE")
			save_gear_cache()
			--print("SAVED GEAR CACHE")
			if Conf.showmsg.REBUILD_FINISH then
				notice("Rebuild finished!")
			end
		end
	--):catch(
	,
		function(err)
			error("During build: " .. tostring(err))
		end
	)
end

local function print_help()
	notice("TODO: help text")
end

--local TEST_COMBINATION_FUNCTION = generate_useful_combinations_v1
--local COMBINATION_FUNCTION = build_gear_continuum

handle_command = function(...) --event_name, ...)
	local args = {...}
	--for iarg = 1, select("#", ...) do
	--	args[iarg] = select(iarg, ...)
	--end
	--for i,v in pairs(args) do args[i] = Client.system.from_shift_jis(Client.system.convert_auto_trans(v)) end

	local subcommand = args[1]
	if (subcommand == "buildaa") then
		build_auto_attack()
	elseif (subcommand == "checkevents") then print(Client.event_system.registered_events)
	elseif (subcommand == 'peep') then peep()
	elseif (subcommand == 'printnext' and (args[2] ~= nil)) then
		local event_name = args[2]
		for i=3,#args do
			event_name = event_name .. " " .. args[i]	
		end
		print("Setting up a reaction to the next: " .. event_name)
		react_to_next(event_name):next(function(...) print({...}) end )
	elseif ((subcommand == 'r') or (subcommand == 'reload')) then
		windower.send_command('lua reload Transmission')
	elseif find({"rebuild", "rb", "build", "b"}, subcommand) then
		rebuild(args)
	elseif find({"cancel", "c"}, subcommand) then
		if REBUILD_IN_PROGRESS then
			CANCEL_REBUILD = os.time()
		else
			error("No operation in progress.")
		end
	elseif subcommand == "help" then
		print_help()
	elseif subcommand == "eval" then
		local eval_str = ""
		for i = 2, #args do
			eval_str = eval_str .. " " .. args[i]
		end
		local eval_func = loadstring(eval_str)
		if eval_func ~= nil then print(eval_func())
		else error("Invalid lua")
		end
	elseif subcommand == "cc" then
		if (not LAST_CLEAR_CACHE_COMMAND) or (os.difftime(os.time(), LAST_CLEAR_CACHE_COMMAND) > Conf.CLEAR_CACHE_COMMAND_CONFIRMATION_TIMEOUT_SECONDS) then
			LAST_CLEAR_CACHE_COMMAND = os.time()
			warning("This will erase the gear set cache, requiring a possibly lengthy '//tm build' before any gear changing can occur again. This should only be used in case of load errors. Issue the command again within " .. Conf.CLEAR_CACHE_COMMAND_CONFIRMATION_TIMEOUT_SECONDS .. " seconds to confirm.")
		else
			if args[2] == nil then
				--GEAR_CACHE = {}
				init_gear_cache()
			else
				if not is_empty(GEAR_CACHE[args[2] ]) then
					GEAR_CACHE.combos[args[2] ] = {}
				end
			end
			save_gear_cache()
		end
	elseif subcommand == "slips" then
		local slips = require('slips')
		--print(slips.storages)
		--for k,v in pairs(slips.storages) do print(k .. ": " .. type(v)) end
		print("slips.get_player_items() = " .. tostring(slips.get_player_items()))
		--print("slips.storages = " .. tostring(slips.storages))
		--slips.get_slip_number_by_id(slip_id)
	elseif subcommand == "showequip" then
		print(Client.item_utils.get_current_equipment())
	else
		print(...)
	end
	
end

--Client.register_event('melee_swing', function (...)
--	print("hello I work")
--end )

Client.register_event('addon_command', handle_command)
--Client.register_event("action",function(action) print(action) end)


notice("Ready!")
