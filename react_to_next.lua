function react_to_next(event, reaction)
    local t = {}
    t.handle = nil
    t.reaction_callback = reaction
    t.react_and_unhook = function(self, event_instance)
        windower.unregister_event(self.handle)
        self.reaction_callback(event_instance)
    end
    local function t_capture(event_instance) t.react_and_unhook(t, event_instance) end
    t.handle = windower.register_event(event, t_capture)
end
