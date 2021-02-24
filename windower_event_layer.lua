local R = {}
local predicates = require("windower_event_predicates")
local utils = {}
R.utils = utils
R.event_predicates = predicates
local handler_factories = {}
R.handler_factories = handler_factories
local event_name_map = {
--  Transmission     Windower
	action            = 'action',
	action_message    = 'action message',
	load              = 'load',
	unload            = 'unload',
	login             = 'login',
	logout            = 'logout',
	gain_buff         = 'gain buff',
	lose_buff         = 'lose buff',
	gain_experience   = 'gain experience',
	lose_experience   = 'lose experience',
	level_up          = 'level up',
	level_down        = 'level down',
	job_change        = 'job change',
	target_change     = 'target change',
	weather_change    = 'weather change',
	status_change     = 'status change',
	hp_change         = 'hp change',
	mp_change         = 'mp change',
	tp_change         = 'tp change',
	hpp_change        = 'hpp change',
	mpp_change        = 'mpp change',
	hpmax_change      = 'hpmax change',
	mpmax_change      = 'mpmax change',
	chat_message      = 'chat message',
	emote             = 'emote',
	party_invite      = 'party invite',
	examined          = 'examined',
	time_change       = 'time change',
	day_change        = 'day change',
	moon_change       = 'moon change',
	linkshell_change  = 'linkshell change',
	zone_change       = 'zone change',
	add_item          = 'add item',
	remove_item       = 'remove item',
	incoming_text     = 'incoming text',
	incoming_chunk    = 'incoming chunk',
	outgoing_text     = 'outgoing text',
	outgoing_chunk    = 'outgoing chunk',
	mouse             = 'mouse',
	keyboard          = 'keyboard',
	ipc_message       = 'ipc message',
	addon_command     = 'addon command',
	unhandled_command = 'unhandled command',
	pipe_message      = 'pipe message',
	prerender         = 'prerender',
	postrender        = 'postrender',
}

R.event_name_map = event_name_map
--R.registration_function = windower.register_event

-- Pass-through events
for t_name, w_name in pairs(event_name_map) do
	handler_factories[w_name] = function(fire_callback)	return function(...) fire_callback(t_name, ...) end end
end

local function from_action(event, target_index, action)
	local ret = shallow_copy(action)
	ret.actor_id = event.actor_id
	ret.target_id = event.targets[target_index].id
	ret.category = event.category
	return ret
end
local make_event_from_action = from_action

local get_player = require('windower_player_utils').get_player

local action_category_names = {
	[0]  = 'action_none',
	[1]  = 'action_attack',
	[2]  = 'action_ranged_finished',
	[3]  = 'action_weaponskill_finish',
	[4]  = 'action_magic_finish',
	[5]  = 'action_item_finish',
	[6]  = 'action_jobability_finish',
	[7]  = 'action_weaponskill_start', -- Doesn't seem to fire on Topaz, don't use?
	[8]  = 'action_magic_start',
	[9]  = 'action_item_start',
	[10] = 'action_jobability_start',
	[11] = 'action_mobability_finish',
	[12] = 'action_ranged_start',
	[13] = 'action_pet_mobability_finish',
	[14] = 'action_dance',
	[15] = 'action_quarry',
	[16] = 'action_sprint',
}
for k,v in pairs(action_category_names) do
	event_name_map[v] = "action"
end

-- translation_functions[event_name][category]
local translation_functions = {
	action = {
		action_attack = function(event)
			--print("Translating melee attack damage: " .. tostring(event.param))
			event.damage = event.param
			event.is_hit = predicates.is_melee_hit(event)
		end
	}
}

function handler_factories.action(fire_callback)

	return function(event)
		local cat_name = action_category_names[event.category]
		if (cat_name == nil) then
			print("UNKNOWN ACTION CATEGORY:")
			print(event)
		end
		local action_event
		for target_index, target_data in pairs(event.targets) do
			for action_index, action in pairs(target_data.actions) do
				action_event = make_event_from_action(event, target_index, action)
				local category_name = action_category_names[event.category]
				local translation_function = translation_functions.action[category_name]
				if (translation_function ~= nil) then
					translation_function(action_event)
				end
				--print("action_event.damage = " .. tostring(action_event.damage))
				fire_callback(cat_name, action_event)
			end
		end
	end
end

function handler_factories.action_message(fire_callback)
	return function(event)
	end
end

-----------------------------------------------------------------------------------

function utils.get_damage(event)
	return event.param
end

function utils.expect(event_name, timeout, predicate)
	local ret_promise = Promise.new()
	local event_reg, timeout_coro
	event_reg = Client.register_event(event_name,
		function (event_object)
			if predicate(event_object) then
				Client.unregister_event(event_reg)
				coroutine.close(timeout_coro)
				ret_promise.resolve(event_object)
			end
		end -- register_event callback
	)
	timeout_coro = coroutine.schedule(
		function()
			Client.unregister_event(event_reg)
			ret_promise.reject("timeout")
			--coroutine.close(timeout_coro) -- Can I close myself? Do I even need to?
		end,
		timeout
	)
	return ret_promise
end  -- function expect()


return R
