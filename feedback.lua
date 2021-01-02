-- Monitors heurisic battle information (hits, misses, evades, etc.)
-- so that the proper weights can be applied to the spectrum of gear sets available

CumAvg = require("cumulative_average")

local heuristics_system = {
--	avg_accuracy = CumAvg.new(),
--	avg_evasion = CumAvg.new(),
-- something[mob_name][job/sjob]
-- player.name .. ":" .. main_job_level .. main_job_abbreviation .. sub_job_level .. sub_job_abbreviation .. " vs " .. mob_name
-- Myuuh:75RDM37NIN vs Om'Aern
-- Note: Make sure the job levels are 2 (or 3?)-length (Item level 119 is a thing)
	mob = {}, -- IDs

	event_system = require("windower_event_layer"),
	event_registry = {}
}

for _, event_name in pairs(heuristics_system.event_system.list_of_events) do
	heuristics_system.event_registry[event_name] = {}
end

-------------------------------------------------------------------------------------------------

function heuristics_system.event_registry.melee_hit_by_player.callback(params)
	local mob_name = params.something_or_antoher
	
end

function heuristics_system.event_registry.melee_miss_by_player.callback(params)
	
end

-------------------------------------------------------------------------------------------------

for event_name, t in pairs(heuristics_system.event_registry) do
	local registration_id = heuristics_system.event_system.register_event(event_name, heuristics_system.event_registry[event_name].callback)
	heuristics_system.event_registry[event_name].id = registration_id
end




--Client.register_event("melee_miss_by_player", test_miss)
--Client.register_event("melee_hit_against_player", test_get_hit)
--Client.register_event("melee_miss_against_player", test_evade)

if windower ~= nil then 
	heuristics_system.event_system = require('windower_event_layer')
elseif ashita ~= nil then
end



--[[
function handle_melee_from_player(digest)
	--print("You took a swing.")
	if digest.is_melee_hit then
		--print("Hit")
		avg_accuracy:add_value(100)
	elseif digest.is_melee_miss then
		--print("Miss")
		avg_accuracy:add_value(0)
	end
	print("Cumulative accuracy: " .. math.floor(avg_accuracy.average) .. "%")
	
end

function handle_melee_attacking_player(event)
end
]]

--[[
function feedback_action_monitor(event)
	if event.actor_id == Client.get_player().id then print(event) end
	local digest = Client.event_utils.digest_event(event)
	if digest.is_melee_from_player then
		handle_melee_from_player(digest)
	elseif digest.is_melee_attacking_player then
	end
end
]]

--[[
function add_to_avg_and_print(n)
	avg_accuracy:add_value(n)
	print("Cumulative accuracy: " .. math.floor(avg_accuracy.average) .. "%")
end

function test_hit(event_params)
	print("Hit!")
	add_to_avg_and_print(100)
end

function test_miss(event_params)
	print("MYEISSED")
	add_to_avg_and_print(0)
end

function test_get_hit(params)
	avg_evasion:add_value(0)
	print("Owwie!")
	print("Cumulative evasion rate: " .. math.floor(avg_evasion.average) .. "%")
end

function test_evade(params)
	avg_evasion:add_value(100)
	print("DOOOOOOOODGE!")
	print("Cumulative evasion rate: " .. math.floor(avg_evasion.average) .. "%")
end
]]

--[[
print("Registering events")
Client.register_event("melee_hit_by_player", test_hit)
Client.register_event("melee_miss_by_player", test_miss)
Client.register_event("melee_hit_against_player", test_get_hit)
Client.register_event("melee_miss_against_player", test_evade)
]]

--print(Client.event_system.registered_events)

return heuristics_system