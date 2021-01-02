print("Running events.lua")

local event_system = {
	registered_events = {},
	__event_id_count__ = 1,
	list_of_events = {
		-- All events...?
		--	actor_id
		--	target_id

		'melee_hit',
		'melee_hit_by_player',
		'melee_hit_against_player',
		'melee_miss',
		'melee_miss_by_player',
		'melee_miss_against_player',
			-- damage: number
			-- TODO: Additional effects, spikes
	}
}

function event_system.register_event(name, callback)
	event_system.registered_events[name] = event_system.registered_events[name] or {}
	local new_index = #(event_system.registered_events[name]) + 1
	local reg = {}
	event_system.registered_events[name][new_index] = reg
	reg.callback = callback
	reg.id = event_system.__event_id_count__
	event_system.__event_id_count__ = event_system.__event_id_count__ + 1
	return reg.id
end

function event_system.unregister_event(id)
	for event_name, regs in pairs(event_system.registered_events) do
		for k,reg in pairs(regs) do
			if reg.id == id then
				regs[k] = nil
			end
		end
	end
end

function event_system.fire(name, params)
	if event_system.registered_events[name] == nil then return end
	for _, reg in pairs(event_system.registered_events[name]) do
		reg.callback(params)
	end
end

return event_system