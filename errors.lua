
-- To create an error:
--      Err = require("errors")
--      ...
--      return Err.new(Err.SOME_ERROR, "message")

--require("debug")

local E = {
    -- only IDs should go here for now
    UNKNOWN_ERROR = 0,
    EVENT_UNREGISTERED = 1,
}
-- Create two-way mapping
for k,v in pairs(E) do E[v] = k end

-- Now we can add methods
E.new = function(id_param, message_param)
    local r = {
        is_error = true,
        id = id_param,
        message = message_param
    }
    r.stack = {}
    local level = 0
    local info
    repeat
        info = debug.getinfo(level)
        r.stack[level] = info
    until info == nil
    r.trace = debug.traceback(message_param)
    return r
end

return E
