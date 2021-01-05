local r = {}

function r.is_player_action(event)
	return (windower.ffxi.get_player().id == event.actor_id)
end

function r.is_melee_swing(ac)
	return (ac.category == 1)
end

function r.is_melee_hit(ac)
	return (r.is_melee_swing(ac) and ac.message == 1)
end
function r.is_melee_miss(ac)
	return (r.is_melee_swing(ac) and ac.message == 15)
end


return r