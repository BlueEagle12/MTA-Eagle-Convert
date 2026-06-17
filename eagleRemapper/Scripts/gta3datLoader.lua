-- Entry point: reads in/data/gta.dat, then drives IMG/IDE/IPL parsing and all
-- of the output writers when the resource starts.

-- "data\maps\LA\lae2.IDE" -> "lae2"
local function getBaseNameNoExt(fullPath)
    local filename = fullPath:match("[^\\/]+$")
    if not filename then
        return fullPath
    end
    return filename:match("^(.*)%.") or filename
end

local function parseGTADat()
    local datPath = "in/data/gta.dat"

    local datFile = fileOpen(datPath)
    if not datFile then
        outputDebugString("Failed to open the gta.dat file at '" .. datPath .. "'!", 1)
        return
    end

    local content = fileRead(datFile, fileGetSize(datFile))
    fileClose(datFile)

    local datEntries = {}

    for line in content:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")

        if line ~= "" and not line:find("^%s*#") then
            local tokens = {}
            for word in line:gmatch("%S+") do
                table.insert(tokens, word)
            end

            local cmd = tokens[1]:upper()   -- e.g. "IDE", "IPL", "COLFILE"
            table.remove(tokens, 1)

            local entry = {command = cmd, tokens = tokens, rawLine = line}

            if cmd == "IDE" or cmd == "IPL" or cmd == "IMG" then
                local path = (tokens[1] or ""):gsub("\\", "/")
                entry.path = path
                entry.shortName = getBaseNameNoExt(path)
            end

            table.insert(datEntries, entry)
        end
    end

    -- First pass (in file order): load IMG containers, validate IDE assets
    -- (prep), and write the placement .map files. IDE parse results are cached
    -- so the second pass doesn't re-read them from disk.
    for _, e in ipairs(datEntries) do
        if e.command == "IMG" then
            parseIMGFile("in/" .. e.path, e.shortName)
        elseif e.command == "IDE" then
            e.cachedDefs = parseIDEFile("in/" .. e.path, e.shortName)
            writeDefinition(e.cachedDefs, "out/zones/" .. e.shortName .. "/" .. e.shortName .. ".definition", e.shortName, true)
        elseif e.command == "IPL" then
            local objects = parseIPLFile("in/" .. e.path, e.shortName)
            writeMapFile(objects, "out/zones/" .. e.shortName .. "/" .. e.shortName .. ".map", e.shortName)
        end
    end

    -- Second pass: write the final .definition files for models that were
    -- actually placed, and log what gta.dat contained.
    for _, e in ipairs(datEntries) do
        if e.command == "IDE" or e.command == "IPL" then
            outputDebugString(("[GTA.DAT] %s => path='%s' shortName='%s'"):format(e.command, e.path or "", e.shortName or ""))

            if e.command == "IDE" then
                writeDefinition(e.cachedDefs, "out/zones/" .. e.shortName .. "/" .. e.shortName .. ".definition", e.shortName)
            end
        else
            outputDebugString(("[GTA.DAT] %s => tokens=[%s]"):format(e.command, table.concat(e.tokens, ", ")))
        end
    end

    prepMetaFile("out/meta.xml")
    writeZoneFile()
    writeDebugFile()
    writeInteriorFile()

    return datEntries
end

addEventHandler("onResourceStart", resourceRoot, function()
    local entries = parseGTADat()
    if entries then
        outputDebugString("Parsed " .. #entries .. " lines from gta.dat!")
    end
end)
