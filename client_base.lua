-- MUST HAVE NO DEPENDENCIES other than Windower or Ashita.
-- If the global Client table needs further augmentation,
-- do it in client.lua
Client = {}

if (windower ~= nil) then
	Client.add_to_chat = windower.add_to_chat -- must come first for print() during debugging
	Client.system = windower
	Client.system_name = 'Windower'
	Client.addon_path = windower.addon_path
	Client.pol_path = windower.pol_path
	Client.resources = require("resources")
	Client.item_utils = require("windower_item_utils")
	Client.player_utils = require('windower_player_utils')
	Client.get_player = function() return merge_right(windower.ffxi.get_player(), windower.ffxi.get_mob_by_target("me")) end
	Client.get_target = function() return windower.ffxi.get_mob_by_target("t") end
	Client.get_items = windower.ffxi.get_items

elseif (ashita ~= nil) then
	Client.system = ashita
	Client.system_name = 'Ashita'
	Client.get_player = function() end

end
