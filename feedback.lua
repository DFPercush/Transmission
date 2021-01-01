-- Monitors heurisic battle information (hits, misses, evades, etc.)
-- so that the proper weights can be applied to the spectrum of gear sets available

require('client')
CumAvg = require("cumulative_average")

local avg_accuracy = CumAvg.new()
local avg_evasion = CumAvg.new()

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

-- Client.register_event("action", feedback_action_monitor)

function add_to_avg_and_print(n)
	avg_accuracy.add_value(n)
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

Client.register_event("melee_hit_by_player", test_hit)
Client.register_event("melee_miss_by_player", test_miss)