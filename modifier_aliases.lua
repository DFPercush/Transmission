
local modifiers = require('modifiers')
require('logger')
local modifier_aliases =
{
	ATT = { "ATK", "ATTACK"},
	
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

	if modifiers[string.upper(alias)] ~= nil then return string.upper(alias) end
	if modifier_alias_map[string.upper(alias)] ~= nil then return modifier_alias_map[string.upper(alias)] end
	return "?"
end
