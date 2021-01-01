
local Promise = require("deferred")
local Err = require("errors")

function react_to_next(event_name, predicate) --, reaction)
    print("setting up a reaction to the next: " .. event_to_hook)
    local t = {}
    t.promise = Promise.new()
    t.handle = nil
    t.reaction_callback = reaction
    t.react_and_unhook = function(self, event_instance)
        if predicate(event_instance) == true then
            print("Unhooking")
            windower.unregister_event(self.handle)
            print("Entering callback")
            --self.reaction_callback(event_instance)
            self.promise:resolve(event_instance)
        end
    end
    t.cancel = function(self)
        windower.unregister_event(self.handle)
        self.promise:reject(Err.EVENT_UNREGISTERED)
    end
    local function t_capture(event_instance) t.react_and_unhook(t, event_instance) end
    t.handle = windower.register_event(event_name, t_capture)
    print("Registered!")
    return t.promise
end
