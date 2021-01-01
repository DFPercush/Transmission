--[[
	All events...?
		actor_id
		target_id

	melee_hit
	melee_hit_by_player
	melee_hit_against_player
	melee_miss
	melee_miss_by_player
	melee_miss_against_player
		damage: number
		TODO: Additional effects, spikes
]]



EventSystem = {
	registered_events = {},
}

__EventSystem_id_count__ = 1

function EventSystem.register_event(name, callback)
	EventSystem.registered_events[name] = EventSystem.registered_events[name] or {}
	local new_index = #(EventSystem.registered_events[name]) + 1
	local reg = {}
	EventSystem.registered_events[name][new_index] = reg
	reg.callback = callback
	reg.id = __EventSystem_id_count__
	__EventSystem_id_count__ = __EventSystem_id_count__ + 1
	return reg.id
end

function EventSystem.unregister_event(id)
	for event_name, regs in pairs(EventSystem.registered_events) do
		for k,reg in pairs(regs) do
			if reg.id == id then
				regs[k] = nil
			end
		end
	end
end

function EventSystem.fire(name, params)
	if EventSystem.registered_events[name] == nil then return end
	for _, reg in pairs(EventSystem.registered_events[name]) do
		reg.callback(params)
	end
end