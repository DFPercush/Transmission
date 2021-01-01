require('client_base')


if (windower ~= nil) then
	--Client.event_utils = require("windower_event_utils")
	require("windower_event_layer")
	Client.item_utils = require("windower_item_utils")
	Client.player_utils = require('windower_player_utils')

elseif (ashita ~= nil) then
	--Client.event_utils = require("ashita_event_utils")

end
