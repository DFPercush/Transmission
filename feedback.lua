-- Monitors heurisic battle information (hits, misses, evades, etc.)
-- so that the proper weights can be applied to the spectrum of gear sets available

--CumAvg = require("cumulative_average")
local RollAvg = require('rolling_average')

local heuristics_system = {
--	avg_accuracy = CumAvg.new(),
--	avg_evasion = CumAvg.new(),
-- something[mob_name][job/sjob]
-- player.name .. ":" .. main_job_level .. main_job_abbreviation .. sub_job_level .. sub_job_abbreviation .. " vs " .. mob_name
-- Myuuh:75RDM37NIN vs Om'Aern
-- Note: Make sure the job levels are 2 (or 3?)-length (Item level 119 is a thing)
	mob = {}, -- IDs

	event_system = require("events"),
	event_registry = {}
}
heuristics_system.test_acc = RollAvg.new()
heuristics_system.test_acc:set_capacity(100)
heuristics_system.test_dmg = RollAvg.new()
heuristics_system.test_dmg:set_capacity(100)

for _, event_name in pairs(heuristics_system.event_system.list_of_events) do
	heuristics_system.event_registry[event_name] = {}
end

-------------------------------------------------------------------------------------------------

function heuristics_system.event_registry.melee_hit_by_player.callback(params)
	--local mob_name = params.something_or_antoher
	heuristics_system.test_acc:add(100)
	heuristics_system.test_dmg:add(params.damage)
	print(heuristics_system.test_dmg:get_average() .. " Damage per hit @ " .. heuristics_system.test_acc:get_average() .. "% Accuracy")
end

function heuristics_system.event_registry.melee_miss_by_player.callback(params)
	heuristics_system.test_acc:add(0)
	print(heuristics_system.test_dmg:get_average() .. " Damage per hit @ " .. heuristics_system.test_acc:get_average() .. "% Accuracy")
end

-------------------------------------------------------------------------------------------------

for event_name, t in pairs(heuristics_system.event_registry) do
	if (t.callback ~= nil) then
		t.id = heuristics_system.event_system.register_event(event_name, t.callback)
	end
end

return heuristics_system