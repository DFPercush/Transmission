
local flags = require('flags')
function generate_useful_combinations_v1(gear_list, purpose, callback)
	-- .....
	-- TODO: Check for off-by-one indices with gear slots? starts at 0 in resources
	local cur_indices = {-1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
	local iteration_min_indices = shallow_copy(cur_indices)
	iteration_min_indices[1] = iteration_min_indices[1] + 1
	local iteration_max_indices = {}
	for x=0,15 do
		iteration_max_indices[x] = tcount(gear_list[x])
	end

	print("max = " .. tostring(iteration_max_indices))
	
	local count = 0
	local built_sets = {}
	local player = get_player()
	local iWeaponMain, iWeaponSub, iRingL, iRingR, iEarL, iEarR
	print("cur at start = " .. array_tostring_horizontal(cur_indices))

	-- Main iterator through all the combinations
	while multi_dimension_next(cur_indices, iteration_min_indices, iteration_max_indices) do
		--print("count=" .. count .. ", cur=" .. array_tostring_horizontal(cur_indices))
		--print("cur_indices = " .. array_tostring_horizontal(cur_indices))
	
		-- Skip duplicate items in rings, earrings and weapons.
		-- Since this tests for equal table references, two distinct items of the
		-- same id will still be able to be equipped.
	
		iEarL = cur_indices[flags.slot_index["Left Ear"]] + 1
		iEarR = cur_indices[flags.slot_index["Right Ear"]] + 1
		iRingL = cur_indices[flags.slot_index["Left Ring"]] + 1
		iRingR = cur_indices[flags.slot_index["Right Ring"]] + 1
		iWeaponMain = cur_indices[flags.slot_index["Main"]] + 1
		iWeaponSub = cur_indices[flags.slot_index["Sub"]] + 1
	
		if ((iEarL ~= iEarR and iEarL < iEarR) or (iEarL == 0 and iEarR == 0))
		 and ((iRingL ~= iRingR and iRingL < iRingR) or (iRingL == 0 and iRingR == 0))
		 and ((iWeaponMain ~= iWeaponSub) or (iWeaponMain == 0 and iWeaponSub == 0))
		 then
			--print("dbg 2")
			-- TODO: Are there any restricted slots? (tunics remove headgear, etc)
			for k,v in pairs(cur_indices) do
				--if RESTRICTED_SLOTS[gear_set[k][v]]
			end
	
			-- Store the utility results and a way to reference the gear set it's looking at
			-- TODO: +? convert code that expects built_set[dimension] to built_sets.apparent_utility_results[dimension]
			built_sets[#built_sets+1] = {
				categorized_gear_list = gear_list,
				purpose_checked_against = purpose,
				apparent_utility_results = purpose.apparent_utility(gear_list, cur_indices, player), -- Main evaluation for the purpose in question.
				indices = shallow_copy(cur_indices)
			}
	
			-- To extract the gear set and equip it, you will need gear_set as well as viable[x].indeces
			-- for each slot, equip gear_set[slot_name][viable[x].indeces[slot_id]]
	
			count = count + 1
			--print("viable = " .. tostring(viable))
		end
	
	
		-- TODO: Remove limiter
		if count > MAX_ITERATIONS_LIMIT then
			print("Reached MAX_ITERATIONS_LIMIT of " .. MAX_ITERATIONS_LIMIT)
			break
		end
	
	
		if (count % PRUNE_SETS_INTERVAL_COUNT == 0) then
			--print(cur_indices[1] .. ", " .. cur_indices[2] .. ", " .. cur_indices[3] .. ", " .. cur_indices[4] .. ", " .. cur_indices[5] .. ", " .. cur_indices[6] .. ", " .. cur_indices[7] .. ", " .. cur_indices[8] .. ", " .. cur_indices[9] .. ", " .. cur_indices[10] .. ", " .. cur_indices[11] .. ", " .. cur_indices[12] .. ", " .. cur_indices[13] .. ", " .. cur_indices[14] .. ", " .. cur_indices[15] .. ", " .. cur_indices[16])
			print("Pruning at cur = " .. array_tostring_horizontal(cur_indices))
			
			prune_sets(built_sets, purpose)
		end -- if count % something
	--until multi_for_next(cur, min, max) == false
	end
	-- Once more with feeling
	prune_sets(built_sets, purpose)
	callback(built_sets)
end
