-- Writes MTA .map files (placements) for each zone.
fileValid = {}
validObject = {}

local function writeInitalMap(mapPath, shortName)
    if fileValid[mapPath] then
        return fileValid[mapPath]
    end

    metaList["Maps"]["zones/" .. shortName .. "/" .. shortName .. ".map"] = true

    local f = fileCreate(mapPath)
    fileValid[mapPath] = f
    if not f then
        outputDebugString("Failed to create map file at: " .. mapPath, 1)
        return
    end

    fileWrite(f, "<map>\n")
    return f
end

local mapFormat = {"id", "posX", "posY", "posZ", "rotX", "rotY", "rotZ", "lodParent", "uniqueID", "lodParentID", "interior"}

local function formatMap(type, id, x, y, z, xr, yr, zr, lodParent, uniqueID, lodParentID, interior)
    local order = {}
    local values = {}
    local input = {
        id, x, y, z, xr, yr, zr,
        lodParent or "",
        (uniqueID or 0) > 0 and uniqueID or "",
        lodParentID or "",
        (tonumber(interior or 0) > 0 and interior or ""),
    }

    for i, v in ipairs(input) do
        if v ~= "" then
            table.insert(order, mapFormat[i])
            values[mapFormat[i]] = v
        end
    end

    local line = string.format("    <%s ", type)
    for _, key in ipairs(order) do
        line = line .. string.format(' %s="%s"', key, values[key])
    end
    line = line .. string.format("></%s>\n", type)

    return line
end

function writeMapFile(objects, mapPath, short)
    local mF

    for _, obj in ipairs(objects or {}) do
        local mName = obj.modelName

        if defValid2[mName] or defaultIDs[mName] or defValid3[mName] then
            zones[short] = true

            mF = writeInitalMap(mapPath, short)

            obj.type = defaultIDs[obj.modelName] and "object" or "building"
            validObject[mName:gsub("%s+", "")] = true

            local line = formatMap(
                obj.type or "building",
                obj.modelName,
                obj.position.x, obj.position.y, obj.position.z,
                obj.rotationEuler.x, obj.rotationEuler.y, obj.rotationEuler.z,
                obj.lodParent,
                obj.uniqueID,
                obj.lodParentID,
                obj.interior
            )

            if mF and line then
                fileWrite(mF, line)
            end
        else
            outputDebugString2("Invalid ID: " .. mName)
        end
    end

    if mF then
        fileWrite(mF, "</map>\n")
        fileClose(mF)
    end

    outputDebugString("Successfully wrote .map file: " .. mapPath)
end
