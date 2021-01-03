local purposes = require "purposes"
--[[

Transmission
An FFXI "gear shifting" addon that automatically finds and optimizes
equipment for various purposes with minimal end user scripting.

By DFPercush and Silver_Skree

]]

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
--MAX_ITERATIONS_LIMIT = 10000000  -- hard fail safe on max run time
--PRUNE_SETS_INTERVAL_COUNT = 1000  -- number of combinations to accumulate before pruning
PROGRESS_REPORT_INTERVAL_MINUTES = 10
LONG_MODE_START_TIME_SECONDS = 22

PERMUTE_BATCH_SIZE = 1000  -- Set combinations
PERMUTE_BATCH_DELAY = 0 -- Seconds
-- There is also TEST_COMBINATION_FUNCTION - use search, must be defined below


-- Abstraction layer
require('client')
PURPOSES = require("purposes") -- Depends on global Client; require client first

-- Client (windower) components
-- TODO: Move to the client module...?
require('chat')
require('logger')
local res = Client.resources
resources = res
__OUTSTANDING_COROUTINES__ = {}
function schedule(f,t) local id = coroutine.schedule(f,t); table.insert(__OUTSTANDING_COROUTINES__, id) end
Client.register_event('unload',function ()
	for i, coroutine_id in pairs(__OUTSTANDING_COROUTINES__) do
		coroutine.close(coroutine_id)
	end
end)



-- Third party libraries
--local Promise = require("deferred")

-- This addon
require('util')
require('feedback')
require('generate_useful_combinations_v1')
--local slot_flags = flags.slot_flags
require("modifier_aliases")
require("multi_hit_weapons")
require("react_to_next")
local Err = require("errors")

require('gear_continuum')





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
	local purpose = purposes.auto_attack
	async_build_gear_continuum('auto_attack'):next(
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
				if d ~= 1 then csv.write(",") end
				csv.write(purpose.dimension_names[d])
			end
			for k,v in pairs(result) do
				--print(get_gear_set_string(v.gear_list_ref, v.indices) .. " : " .. array_tostring_horizontal(v.apparent_utility_results))
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
			return "Finished output"
		end
	):catch(function (why)
		error("Calculation interrupted: " .. tostring(why))
	end)
end


--local TEST_COMBINATION_FUNCTION = generate_useful_combinations_v1
--local COMBINATION_FUNCTION = build_gear_continuum

handle_command = function(...)
	local args = {...}[1]
	local subcommand = args[1]

	if (subcommand == "buildaa") then build_auto_attack()
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
	else
		print(args)
	end
	
end

Client.register_event('addon_command', handle_command)
--Client.register_event("action",function(action) print(action) end)
print("Loaded!")