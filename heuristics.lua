-- Monitors heurisic battle information (hits, misses, evades, etc.)
-- so that the proper weights can be applied to the spectrum of gear sets available

-- TODO: Settings?
local DEFAULT_ROLLING_AVERAGE_CAPACITY = 20

--CumAvg = require("cumulative_average")
local RollAvg = require('rolling_average')

local heuristics_system = {
--	avg_accuracy = CumAvg.new(),
--	avg_evasion = CumAvg.new(),
-- something[mob_name][job/sjob]
-- player.name .. ":" .. main_job_level .. main_job_abbreviation .. sub_job_level .. sub_job_abbreviation .. " vs " .. mob_name
-- Myuuh:75RDM37NIN vs Om'Aern
-- Note: Make sure the job levels are 2 (or 3?)-length (Item level 119 is a thing)
	--mob = {}, -- IDs

	event_system = require("events"),
	event_registry = {},
}
--heuristics_system.test_acc = RollAvg.new()
--heuristics_system.test_acc.set_capacity(100)
--heuristics_system.test_dmg = RollAvg.new()
--heuristics_system.test_dmg.set_capacity(100)

--for _, event_name in pairs(heuristics_system.event_system.list_of_events) do
--	heuristics_system.event_registry[event_name] = {}
--end

-------------------------------------------------------------------------------------------------

function heuristics_system.get_vs_string(player, mob)
	-- TODO: ensure that job levels are always the same character length (probably 3), pad-left with zeroes
	--return player.name .. " " .. player.main_job .. player.main_job_level .. player.sub_job .. player.sub_job_level .. " " .. mob.name
	return player.name .. " " .. player.main_job .. player.sub_job .. " " .. mob.name
end

-- Gets the correct table for the player's current job and the mob they're fighting
function heuristics_system.cur() --player, mob)
	local player = Client.player_utils.get_player()
	local job_name = player.main_job
	local mob_name
	local mob_obj = Client.get_current_battle_target()
	if mob_obj == nil then mob_obj = Client.get_current_target() end
	if mob_obj == nil then mob_name = "no_target"
	else mob_name = mob_obj.name
	end
	local vs = heuristics_system.get_vs_string(player, mob_obj)
	heuristics_system[vs] = heuristics_system[vs] or {}
	local r
	--print(vs)
	--print(tcount(heuristics_system[vs]))
	if (heuristics_system[vs] == nil) then
		--print("initializing heuristics_system[" .. vs .. "]")
		heuristics_system[vs] = {}
	end
	r = heuristics_system[vs]
	if r.acc == nil then
		r.acc = RollAvg.new()
		r.acc.set_capacity(DEFAULT_ROLLING_AVERAGE_CAPACITY)
	end
	if r.dmg == nil then
		r.dmg = RollAvg.new()
		r.dmg.set_capacity(DEFAULT_ROLLING_AVERAGE_CAPACITY)
	end
	return r
end

function heuristics_system.using_item(itemid)
	GEAR_CACHE = GEAR_CACHE or {}
	GEAR_CACHE.last_used = GEAR_CACHE.last_used or {}
	local now = os.time()
	GEAR_CACHE.last_used[itemid] = now
end

function heuristics_system.get_least_used_equipment(all_items_flat_list)
	local ret = {}
	local sorting = {}
	if GEAR_CACHE and GEAR_CACHE.last_used then
		for itemid, time in pairs(GEAR_CACHE.last_used) do
			table.insert(sorting, {itemid=itemid, time=time})
		end
		table.sort(sorting,
			function(a,b)
				return (a.time - b.time)
			end
		)
	end
	--table.sort()
	--local all = Client.item_utils.get_all_items() -- bad dependency
	local equippable_items_by_id = {}
	for _, item in pairs(all_items_flat_list) do
		--if find({"inventory", "wardrobe", "wardrobe2", "wardrobe4"}, ((type(item)=="table" and item.storage) or "?"))
		if find({"inventory", "wardrobe", "wardrobe2", "wardrobe4"}, item.storage) then
			equippable_items_by_id[item.id] = item
			if GEAR_CACHE.last_used[item.id] == nil then
				table.insert(ret, item)
			end
		end
	end
	for _, used in ipairs(sorting) do
		if equippable_items_by_id[used.itemid] then
			table.insert(ret, equippable_items_by_id[used.itemid])
		end
	end
end


-------------------------------------------------------------------------------------------------
local predicates = heuristics_system.event_system.predicates
local registry = heuristics_system.event_registry

registry.melee_swing_by_player = {
	event_name = "action_attack",
	predicate = function(event)
		return (predicates.is_melee_swing(event) and predicates.is_player_action(event))
	end,
	callback = function(event)
		--local mob_name = event.something_or_antoher
		--print("melee_hit_by_player")
		if predicates.is_melee_hit(event) then
			heuristics_system.cur().acc.add(1)
			heuristics_system.cur().dmg.add(event.damage)
		elseif predicates.is_melee_miss(event) then
			heuristics_system.cur().acc.add(0)
		end
		if Conf.showmsg.AVERAGE_DAMAGE_ACCURACY then
			print(round(heuristics_system.cur().dmg.get_average()) .. " Damage per hit @ " .. round(heuristics_system.cur().acc.get_average() * 100) .. "% Accuracy")
		end
	end
}


-------------------------------------------------------------------------------------------------


-- Equipment usage data, for determining what to swap out to storage
local function monitor_equipment_usage_coro()
	if Client.get_player().status ~= "zoning" then -- TODO: Status id numbers, it's not a string
		local equip = Client.item_utils.get_current_equipment()
		print(equip)
		for i=0,15 do
			local slot_name = string.lower(resources.slots[i].en):gsub(" ", "_")
			local item = Client.system.ffxi.get_items(equip[slot_name .. "_bag"], equip[slot_name])
			local itemid = (item and item.id) or 0
			heuristics_system.using_item(itemid)
		end
	end
	schedule(monitor_equipment_usage_coro, 1)
end
schedule(monitor_equipment_usage_coro, 1)
-- TODO: Load from cache



-------------------------------------------------------------------------------------------------

for _, t in pairs(heuristics_system.event_registry) do
	if (t.callback ~= nil) then
		t.id = heuristics_system.event_system.register_event(t.event_name, t.callback, t.predicate)
	end
end

return heuristics_system
