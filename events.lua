local event_system = {
	registered_events = {},
	__event_id_count__ = 1,
	--[[
	list_of_events = {
		-- All action events...?
		--	actor_id
		--	target_id

		'melee_swing',
		'melee_swing_by_player',
		'melee_hit',
		'melee_hit_by_player',
		'melee_hit_against_player',
		'melee_miss',
		'melee_miss_by_player',
		'melee_miss_against_player',
			-- damage: number
			-- TODO: Additional effects, spikes

		'addon_command',
			-- TODO: Accept arguments and stuff for greater control!

		'unload'
	},
	]]
}
if (windower ~= nil) then
	local temp = require('windower_event_layer')
	event_system.predicates = temp.event_predicates
	event_system.handler_factories = temp.handler_factories
	event_system.event_name_map = temp.event_name_map
	event_system.utils = temp.utils
	--event_system.bare_registration_function = temp.registration_function
end

function event_system.register_event(name, callback, opt_predicate)
	event_system.registered_events[name] = event_system.registered_events[name] or {}
	local new_index = #(event_system.registered_events[name]) + 1
	local reg = {}
	event_system.registered_events[name][new_index] = reg
	reg.callback = callback
	reg.id = event_system.__event_id_count__
	if (opt_predicate == nil) then reg.predicate = function() return true end else reg.predicate = opt_predicate end
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

function event_system.fire(name, params, ...)
	if event_system.registered_events[name] == nil then return end
	if type(params) == "table" then
		params.event_name = name
	end
	for _, reg in pairs(event_system.registered_events[name]) do
		if (reg.predicate(params) == true) then
			reg.callback(params, ...)
		end
	end
end


-- Passthrough
if (windower ~= nil) then
	for event_name, make_handler in pairs(event_system.handler_factories) do
		local handler_function = make_handler(event_system.fire)
		local system_event_name = event_system.event_name_map[event_name]
		windower.register_event(system_event_name or event_name, handler_function)
	end
elseif (ashita ~= nil) then
end



return event_system