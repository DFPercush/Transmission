require('client_base')


if (windower ~= nil) then
	Client.item_utils = require("windower_item_utils")
	Client.player_utils = require('windower_player_utils')

elseif (ashita ~= nil) then
end

Client.heuristics = require("feedback")
Client.event_system = Client.heuristics.event_system
Client.register_event = Client.event_system.register_event
Client.unregister_event = Client.event_system.unregister_event