-- Writes interiors.map from the enter/exit (enex) markers collected by the IPL
-- loader, producing interiorEntry / interiorReturn pairs.

local function writeInitalInt()
    local f = fileCreate("out/interiors.map")
    if not f then
        outputDebugString("Failed to create interior file at: out/interiors.map", 1)
        return
    end
    fileWrite(f, "<map>\n")
    return f
end

local intFormat = {"id", "posX", "posY", "posZ", "rotation", "interior", "oneway", "dimension"}

-- idType lets the same layout produce either an "id" attribute (interiorEntry)
-- or a "refid" attribute (interiorReturn).
local function formatInteriorLine(tagName, idType, id, x, y, z, rot, interior)
    local input = {id, x, y, z, rot, interior, "false", 0}

    local line = string.format("    <%s ", tagName)
    for i, value in ipairs(input) do
        local key = (intFormat[i] == "id") and idType or intFormat[i]
        line = line .. string.format(' %s="%s"', key, value)
    end
    line = line .. " />\n"

    return line
end

function writeInteriorFile()
    local iF = writeInitalInt()
    if not iF then
        return
    end

    for id, obj in pairs(enexEntires) do
        local tIn = obj[1]
        local tOut = obj[2]

        if tOut then
            local entryPos = tOut.entryPosition
            local exitPos = tIn.exitPosition

            fileWrite(iF, formatInteriorLine(
                "interiorEntry", "id",
                id .. "-exit", entryPos.x, entryPos.y, entryPos.z, entryPos.zr, tOut.int
            ))

            fileWrite(iF, formatInteriorLine(
                "interiorReturn", "refid",
                id .. "-exit", exitPos.x, exitPos.y, exitPos.z, exitPos.zr, tIn.int
            ))
        end
    end

    fileWrite(iF, "</map>\n")
    fileClose(iF)

    outputDebugString("Successfully wrote interior file")
end
