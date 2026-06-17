-- Parses GTA .IPL files: object instances ("inst" block) and interior markers
-- ("enex" block). Quaternion rotations are converted to Euler angles and the
-- configured map offset is applied to every placement.
uniqueIDs = {}
enexEntires = {}
lodCols = {}

function parseIPLFile(iplPath, short)
    local iplFile = fileOpen(iplPath)
    if not iplFile then
        outputDebugString2("Failed to open the IPL file at '" .. iplPath .. "'!", 1)
        return
    end

    local content = fileRead(iplFile, fileGetSize(iplFile))
    fileClose(iplFile)

    local inInstBlock = false
    local inEnexBlock = false
    local currentIndex = 0
    local instEntries = {}

    for line in content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.*)")  -- trim leading spaces

        if line:lower():find("^inst") then
            inInstBlock = true
            currentIndex = 0
            inEnexBlock = false
        elseif line:lower():find("^end") and inInstBlock then
            inInstBlock = false
            inEnexBlock = false
        elseif line:lower():find("^enex") and (not inInstBlock) then
            inEnexBlock = true
        end

        if inInstBlock then
            -- Skip the 'inst' header and comment lines
            if line:lower() ~= "inst" and not line:find("^%s*%-%-") and not line:find("#") then
                local fields = {}
                for val in line:gmatch("([^,]+)") do
                    table.insert(fields, val:match("^%s*(.-)%s*$"))
                end

                -- Fields: 1=modelID, 2=modelName, 3=interior, 4-6=pos,
                -- 7-9=rot (x,y,z), 10=rotW, 11=LOD index. Some lines omit rotW.
                if #fields >= 10 then
                    local modelID   = tonumber(fields[1]) or 0
                    local modelName = fields[2] or ""
                    local interior  = tonumber(fields[3]) or 0
                    local posX      = (tonumber(fields[4]) or 0) + mapOffset[1]
                    local posY      = (tonumber(fields[5]) or 0) + mapOffset[2]
                    local posZ      = (tonumber(fields[6]) or 0) + mapOffset[3]
                    local rotX      = tonumber(fields[7]) or 0
                    local rotY      = tonumber(fields[8]) or 0
                    local rotZ      = tonumber(fields[9]) or 0
                    local rotW      = 0
                    local lodVal    = -1

                    if #fields == 10 then
                        -- No separate rotW; treat field 10 as the LOD index
                        lodVal = tonumber(fields[10]) or -1
                    elseif #fields >= 11 then
                        rotW   = tonumber(fields[10]) or 0
                        lodVal = tonumber(fields[11]) or -1
                    end

                    local roll, pitch, yaw = quatToEuler(rotX, rotY, rotZ, rotW)

                    if string.find(string.lower(modelName), "lod") then
                        uniqueIDs[modelName] = (uniqueIDs[modelName] or -1) + 1
                    end

                    instEntries[currentIndex] = {
                        index       = currentIndex,
                        modelID     = modelID,
                        modelName   = modelName,
                        interior    = interior,
                        uniqueID    = uniqueIDs[modelName] or 0,
                        position      = {x = posX, y = posY, z = posZ},
                        rotationQuat  = {x = rotX, y = rotY, z = rotZ, w = rotW},
                        rotationEuler = {x = roll, y = pitch, z = yaw},
                        lodIndexRef = lodVal,
                        fullLine    = line,
                    }
                    currentIndex = currentIndex + 1
                end
            end
        elseif inEnexBlock then
            if line:lower() ~= "enex" and not line:find("^%s*%-%-") and not line:find("#") then
                local fields = {}
                for val in line:gmatch("([^,]+)") do
                    table.insert(fields, val:match("^%s*(.-)%s*$"))
                end

                if #fields >= 18 then
                    interiorValid = true

                    local enX = tonumber(fields[1]) or 0
                    local enY = tonumber(fields[2]) or 0
                    local enZ = tonumber(fields[3]) or 0
                    local enR = tonumber(fields[4]) or 0
                    local enWX = tonumber(fields[5]) or 0
                    local enWY = tonumber(fields[6]) or 0

                    local exX = tonumber(fields[8]) or 0
                    local exY = tonumber(fields[9]) or 0
                    local exZ = tonumber(fields[10]) or 0
                    local exR = tonumber(fields[11]) or 0

                    local tarI = tonumber(fields[12]) or 0
                    local flag = tonumber(fields[13]) or 0
                    local nameFix = (fields[14] or ""):gsub('"', "")

                    local tOn = tonumber(fields[17]) or 0
                    local tOff = tonumber(fields[18]) or 0

                    enexEntires[nameFix] = enexEntires[nameFix] or {}

                    table.insert(enexEntires[nameFix], {
                        entryPosition = {x = enX, y = enY, z = enZ, zr = enR, wX = enWX, wY = enWY},
                        exitPosition  = {x = exX, y = exY, z = exZ, zr = exR},
                        type = flag,
                        on   = tOn,
                        off  = tOff,
                        id   = nameFix .. "_" .. short,
                        int  = tarI,
                    })
                end
            end
        end
    end

    -- Link LOD references: an instance whose lodIndexRef points at another
    -- instance inherits that instance's model name as its LOD parent.
    for _, obj in ipairs(instEntries) do
        if obj.lodIndexRef >= 0 then
            local lodObj = instEntries[obj.lodIndexRef]
            if lodObj then
                obj.lodParent = lodObj.modelName
                lodCols[lodObj.modelName] = obj.modelName
                lodCols[obj.modelName] = lodObj.modelName
                if lodObj.uniqueID > 0 then
                    obj.uniqueID = lodObj.uniqueID
                end
            end
        end
    end

    return instEntries
end
