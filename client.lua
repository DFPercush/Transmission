require('client_base')


if (windower ~= nil) then
elseif (ashita ~= nil) then
end

Client.heuristics = require("feedback")
Client.event_system = Client.heuristics.event_system
Client.register_event = Client.event_system.register_event
Client.unregister_event = Client.event_system.unregister_event