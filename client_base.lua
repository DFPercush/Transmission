-- MUST HAVE NO DEPENDENCIES other than Windower or Ashita.
-- If the global Client table needs further augmentation,
-- do it in client.lua
Client = {}

if (windower ~= nil) then
	Client.system = windower
	Client.system_name = 'Windower'
	Client.resources = require("resources")
	Client.get_player = function() return merge_right(windower.ffxi.get_player(), windower.ffxi.get_mob_by_target("me")) end
	Client.get_target = function() return windower.ffxi.get_mob_by_target("t") end
	Client.get_items = windower.ffxi.get_items
	Client.add_to_chat = windower.add_to_chat

elseif (ashita ~= nil) then
	Client.system = ashita
	Client.system_name = 'Ashita'
	Client.get_player = function() end

end
