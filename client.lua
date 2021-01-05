require('client_base')


if (windower ~= nil) then
elseif (ashita ~= nil) then
end

Client.heuristics_system = require("heuristics")
Client.event_system = Client.heuristics_system.event_system
Client.register_event = Client.event_system.register_event
Client.unregister_event = Client.event_system.unregister_event
