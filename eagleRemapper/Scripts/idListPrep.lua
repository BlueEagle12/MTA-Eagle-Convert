-- Loads the list of stock San Andreas model IDs so the exporter can tell which
-- model names are built-in (objects) versus custom (buildings).
defaultIDs = {}

local function getLines(file)
    local fData = fileRead(file, fileGetSize(file))
    if not fData then
        print("Error: Unable to read file - " .. tostring(file))
        return {}
    end

    local fProcessed = split(fData, 10)
    fileClose(file)
    return fProcessed
end

local idList = getLines(fileOpen("scripts/validID/sa_id_list.ID"))

for _, v in ipairs(idList) do
    local strings = split(v, ",")
    if strings[1] then
        local name = strings[2]
        defaultIDs[name:gsub("%s+", "")] = tonumber(strings[1])
    end
end
