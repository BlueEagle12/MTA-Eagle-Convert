-- Generates the output resource's meta.xml, the zone list, and the debug log.

local function fileEntry(src)
    return {tag = "file", attributes = {src = src, type = "client"}}
end

local function writeMetaFile(entries, metaPath)
    local f = fileCreate(metaPath)
    if not f then
        outputDebugString("Failed to create " .. metaPath, 1)
        return false
    end

    fileWrite(f, "<meta>\n")

    for _, entry in ipairs(entries) do
        if entry == "blank" then
            fileWrite(f, "\n\n")
        else
            local tag = entry.tag or "info"
            local line = "    <" .. tag
            for k, v in pairs(entry.attributes or {}) do
                line = line .. string.format(' %s="%s"', k, tostring(v))
            end
            fileWrite(f, line .. " />\n")
        end
    end

    fileWrite(f, "</meta>\n")
    fileClose(f)

    outputDebugString("Wrote meta.xml to: " .. metaPath)
    return true
end

function writeZoneFile()
    local f = fileCreate("out/eagleZones.txt")
    if not f then
        outputDebugString("Failed to create eagleZones.txt", 1)
        return false
    end

    for zone in pairs(zones) do
        fileWrite(f, zone .. "\n")
    end

    fileClose(f)
    outputDebugString("Wrote eagleZones.txt to: out/eagleZones.txt")
    return true
end

function writeDebugFile()
    local f = fileCreate("debug.txt")
    if not f then
        return false
    end

    for _, entry in ipairs(debugLines) do
        fileWrite(f, entry .. "\n")
    end

    fileClose(f)
    outputDebugString("Wrote debug to: debug.txt")
    return true
end

local metaListOrder = {"Water", "Maps", "Definitions", "Models", "Collisons", "Textures"}

function prepMetaFile(path)
    local entries = {}

    -- Info + zone list, pulled from the configured map name/author.
    table.insert(entries, {tag = "info", attributes = {author = mAuthor, version = "3.0.0", name = mapName}})
    table.insert(entries, "blank")
    table.insert(entries, fileEntry("eagleZones.txt"))
    table.insert(entries, "blank")

    if fileExists("in/data/water.dat") then
        copyFile("in/data/water.dat", "out/water.dat", "Water", "water.dat")
    end

    if interiorValid then
        table.insert(entries, fileEntry("interiors.map"))
        table.insert(entries, "blank")
    end

    if IMGSupport then
        table.insert(entries, fileEntry("imgs/dff.img"))
        table.insert(entries, fileEntry("imgs/col.img"))
        table.insert(entries, fileEntry("imgs/txd.img"))
        table.insert(entries, "blank")
    end

    for _, index in ipairs(metaListOrder) do
        for src in pairs(metaList[index]) do
            table.insert(entries, fileEntry(src))
        end
        table.insert(entries, "blank")
    end

    writeMetaFile(entries, path)
end
