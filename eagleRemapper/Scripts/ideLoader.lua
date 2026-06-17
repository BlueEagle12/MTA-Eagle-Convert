-- Parses GTA .IDE files, extracting object definitions from the "objs" and
-- "tobj" (timed object) blocks.
defValid2 = {}

-- Field index layouts differ by column count, matching the variants the
-- original maps were authored with:
--   5 cols: id, model, txd, drawDist, flags
--   6 cols: id, model, txd, _, drawDist, flags
--   7 cols: id, model, txd, drawDist, flags, timeIn, timeOut
local fieldLayouts = {
    [5] = {drawDist = 4, flags = 5},
    [6] = {drawDist = 5, flags = 6},
    [7] = {drawDist = 4, flags = 5, timeIn = 6, timeOut = 7},
}

local function buildEntry(fields, layout, zoneName)
    local modelName = fields[2] or ""
    local flagsVal = tonumber(fields[layout.flags]) or 0

    defValid2[modelName:gsub("%s+", "")] = true

    return {
        id        = tonumber(fields[1]) or 0,
        modelName = modelName,
        txdName   = fields[3] or "",
        drawDist  = tonumber(fields[layout.drawDist]) or 0,
        flagsVal  = flagsVal,                       -- original integer
        flagsBits = parseFlagsToList(flagsVal),     -- table of bit positions that are ON
        zone      = zoneName,
        tIn       = layout.timeIn and tonumber(fields[layout.timeIn]) or nil,
        tOut      = layout.timeOut and tonumber(fields[layout.timeOut]) or nil,
        fullLine  = nil,
    }
end

function parseIDEFile(idePath, name)
    if not fileExists(idePath) then
        return
    end

    local ideFile = fileOpen(idePath)
    if not ideFile then
        outputDebugString2("Failed to open the IDE file at '" .. idePath .. "'!", 1)
        return
    end

    local content = fileRead(ideFile, fileGetSize(ideFile))
    fileClose(ideFile)

    local inObjsBlock = false
    local intObjsBlock = false
    local objsEntries = {}

    for line in content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")

        if line ~= "" and not line:find("^%s*%-%-") then
            if line:lower():find("^objs") then
                inObjsBlock = true
            elseif line:lower():find("^tobj") then
                intObjsBlock = true
            elseif line:lower():find("^end") and inObjsBlock then
                inObjsBlock = false
            elseif line:lower():find("^end") and intObjsBlock then
                intObjsBlock = false
            elseif line:lower():find("#") then
                -- Ignore directive/comment lines
            elseif inObjsBlock or intObjsBlock then
                local fields = {}
                for val in line:gmatch("([^,]+)") do
                    table.insert(fields, val:match("^%s*(.-)%s*$"))
                end

                local layout = fieldLayouts[#fields]
                if layout then
                    local parsed = buildEntry(fields, layout, name)
                    parsed.fullLine = line
                    table.insert(objsEntries, parsed)
                else
                    outputDebugString2("Warning: skipping malformed line in objs block: " .. line .. "," .. name, 2)
                end
            end
        end
    end

    return objsEntries
end
