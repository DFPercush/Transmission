
local modifiers = require('modifiers')
require('logger')
local modifier_aliases =
{
    ATT = { "atk", "attack"},
    
}

-- Build a cache of aliases --> modifier names
local modifier_alias_map = {}
for modifier_name, aliases in pairs(modifier_aliases) do
    for _, alias in pairs(aliases) do
        if modifier_alias_map[alias] ~= nil then
            warn("Duplicate modifier alias: " .. alias)
        end
        modifier_alias_map[alias] = modifier_name
    end
end

function get_modifier_by_alias(alias)
    if modifiers[alias] ~= nil then return alias end
    if modifier_alias_map[alias] ~= nil then return modifier_alias_map[alias] end
    return "?"
end
