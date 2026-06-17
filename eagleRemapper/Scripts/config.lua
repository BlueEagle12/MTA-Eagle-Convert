-- Configuration is defined in the <settings> block of meta.xml and read here
-- into globals the rest of the resource uses. Edit the values in meta.xml (or
-- from the server admin panel) rather than editing this file.

local function getSetting(name, default)
    local value = get(name)
    if value == nil then
        return default
    end
    return value
end

mapName    = getSetting("*mapName", "Output")
mAuthor    = getSetting("*author", "Blue Eagle")

-- get() returns booleans/numbers when the stored value looks like one, but be
-- tolerant of plain strings too ("true"/"false").
local imgValue = getSetting("*IMGSupport", false)
IMGSupport = (imgValue == true) or (imgValue == "true")

mapOffset = {
    tonumber(getSetting("*offsetX", 0)) or 0,
    tonumber(getSetting("*offsetY", 0)) or 0,
    tonumber(getSetting("*offsetZ", 0)) or 0,
}
