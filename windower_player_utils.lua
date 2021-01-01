require('client_base')

local R = {}

function R.get_dual_wield_level(player)
	player = player or Client.get_player()
	if player.main_job == "NIN" then
		if player.main_job_level >= 85 then return 5
		elseif player.main_job_level >= 65 then return 4
		elseif player.main_job_level >= 45 then return 3
		elseif player.main_job_level >= 25 then return 2
		elseif player.main_job_level >= 10 then return 1
		end
	elseif player.main_job == "DNC" then
		if player.main_job_level >= 80 then return 4
		elseif player.main_job_level >= 60 then return 3
		elseif player.main_job_level >= 40 then return 2
		elseif player.main_job_level >= 20 then return 1
		end
	elseif player.main_job == "THF" then
		if (player.main_job_level >= 99) and ((player.job_points.thf.jp_spent + player.job_points.thf.job_points) >= 550) then return 4
		elseif (player.main_job_level >= 98) then return 3
		elseif (player.main_job_level >= 87) then return 2
		elseif (player.main_job_level >= 83) then return 1
		end
	elseif player.main_job == "BLU" then
		if (player.main_job_level >= 99) and ((player.job_points.blue.jp_spent + player.job_points.blu.job_points) >= 100) then return 4
		elseif player.main_job_level >= 99 then return 3
		elseif player.main_job_level >= 89 then return 2
		elseif player.main_job_level >= 80 then return 1
		end
	end

	if player.sub_job == "NIN" then
		if player.sub_job_level >= 85 then return 5
		elseif player.sub_job_level >= 65 then return 4
		elseif player.sub_job_level >= 45 then return 3
		elseif player.sub_job_level >= 25 then return 2
		elseif player.sub_job_level >= 10 then return 1
		end
	elseif player.sub_job == "DNC" then
		if player.sub_job_level >= 80 then return 4
		elseif player.sub_job_level >= 60 then return 3
		elseif player.sub_job_level >= 40 then return 2
		elseif player.sub_job_level >= 20 then return 1
		end
	elseif player.sub_job == "THF" then
		if (player.sub_job_level >= 98) then return 3
		elseif (player.sub_job_level >= 87) then return 2
		elseif (player.sub_job_level >= 83) then return 1
		end
	elseif player.sub_job == "BLU" then
		if player.sub_job_level >= 99 then return 3
		elseif player.sub_job_level >= 89 then return 2
		elseif player.sub_job_level >= 80 then return 1
		end
	end
	return 0
end

function R.get_martial_arts_level(player)
	player = player or Client.get_player()
	if player.main_job == "MNK" then
		if player.main_job_level >= 82 then return 7
		elseif player.main_job_level >= 75 then return 6
		elseif player.main_job_level >= 61 then return 5
		elseif player.main_job_level >= 46 then return 4
		elseif player.main_job_level >= 31 then return 3
		elseif player.main_job_level >= 16 then return 2
		else return 1
		end
	elseif player.main_job == "PUP" then
		if player.main_job_level >= 97 then return 5
		elseif player.main_job_level >= 86 then return 4
		elseif player.main_job_level >= 75 then return 3
		elseif player.main_job_level >= 50 then return 2
		elseif player.main_job_level >= 25 then return 1
		end
	end
	if player.sub_job == "MNK" then
		if player.sub_job_level >= 82 then return 7
		elseif player.sub_job_level >= 75 then return 6
		elseif player.sub_job_level >= 61 then return 5
		elseif player.sub_job_level >= 46 then return 4
		elseif player.sub_job_level >= 31 then return 3
		elseif player.sub_job_level >= 16 then return 2
		else return 1
		end
	elseif player.sub_job == "PUP" then
		if player.sub_job_level >= 97 then return 5
		elseif player.sub_job_level >= 86 then return 4
		elseif player.sub_job_level >= 75 then return 3
		elseif player.sub_job_level >= 50 then return 2
		elseif player.sub_job_level >= 25 then return 1
		end
	end	   
	return 0
end

return R