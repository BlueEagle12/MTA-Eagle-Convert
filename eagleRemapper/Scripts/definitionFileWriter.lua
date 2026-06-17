-- Writes MTA .definition files (zone model definitions) and copies the
-- referenced dff/col/txd assets into the output. Runs in two modes:
--   prep = true  : validate assets and populate defValid3, write nothing
--   prep = false : write definitions for models that were actually placed
local defFileValid = {}
defValid3 = {}
changedCOL = {}
zones = {}

local function writeInital(definitionPath, shortName)
    if defFileValid[definitionPath] then
        return defFileValid[definitionPath]
    end

    metaList["Definitions"]["zones/" .. shortName .. "/" .. shortName .. ".definition"] = true

    local f = fileCreate(definitionPath)
    defFileValid[definitionPath] = f
    if not f then
        outputDebugString2("Failed to create definition file at: " .. definitionPath, 1)
        return
    end

    fileWrite(f, "<zoneDefinitions>\n")
    return f
end

-- Picks the IMG-flattened path or the plain per-zone path depending on
-- IMGSupport, and returns both the destination (out/...) and the relative path
-- used for meta registration.
local function assetPaths(imgRel, plainRel)
    local rel = IMGSupport and imgRel or plainRel
    return "out/" .. rel, rel
end

function writeDefinition(definitions, definitionPath, shortName, prep)
    local f

    for _, def in ipairs(definitions or {}) do
        local dName = def.modelName

        if defaultIDs[dName:gsub("%s+", "")] then
            outputDebugString("Notice: skipping default IDE object: " .. defaultIDs[dName:gsub("%s+", "")], 2)
        elseif validObject[dName:gsub("%s+", "")] or prep then
            local dZone = def.zone

            local model = "in/resources/" .. def.modelName .. ".dff"
            local col   = "in/resources/" .. def.modelName .. ".col"
            local txd   = "in/resources/" .. def.txdName .. ".txd"

            local invalid = false
            local reason = ""

            local dffDst, dffReg = assetPaths("dffImg/" .. def.modelName .. ".dff", "zones/" .. dZone .. "/dff/" .. def.modelName .. ".dff")
            local valid, reasonA = copyFile(model, dffDst, "Models", dffReg, prep, IMGSupport)
            invalid = (not valid) or invalid
            reason = reason .. "," .. (reasonA or "")

            if not invalid then
                local reasonB
                local colDst, colReg = assetPaths("colImg/" .. def.modelName .. ".col", "zones/" .. dZone .. "/col/" .. def.modelName .. ".col")
                valid, reasonB = copyFile(col, colDst, "Collisons", colReg, prep, IMGSupport)

                if not valid then
                    local lodCOL = lodCols[def.modelName]
                    if lodCOL then
                        local lodDst, lodReg = assetPaths("colImg/" .. lodCOL .. ".col", "zones/" .. dZone .. "/col/" .. lodCOL .. ".col")
                        valid, reasonB = copyFile("in/resources/" .. lodCOL .. ".col", lodDst, "Collisons", lodReg, prep, IMGSupport)
                        changedCOL[def.modelName] = lodCOL
                    end
                end

                invalid = (not valid) or invalid
                reason = reason .. "," .. (reasonB or "")
            end

            if not invalid then
                local reasonC
                local txdDst, txdReg = assetPaths("txdImg/" .. def.txdName .. ".txd", "textures/" .. def.txdName .. ".txd")
                valid, reasonC = copyFile(txd, txdDst, "Textures", txdReg, prep, IMGSupport)
                invalid = (not valid) or invalid
                reason = reason .. "," .. (reasonC or "")
            end

            local line
            if not invalid then
                if not prep then
                    f = writeInital(definitionPath, shortName)
                end

                if not def.tIn then
                    local tIna, tOuta = timeCalculator(def.modelName)
                    if tIna then
                        def.tIn = tIna
                        def.tOut = tOuta
                    end
                end

                defValid3[def.modelName] = true

                if def.modelName and def.zone and def.txdName and def.drawDist then
                    if not prep then
                        zones[def.zone] = true
                    end

                    if def.tIn and def.tOut then
                        line = string.format(
                            '    <definition id="%s" zone="%s" col="%s" txd="%s" flags="%s" lodDistance="%s" timeIn="%s" timeOut="%s"></definition>\n',
                            def.modelName, def.zone, (changedCOL[def.modelName] or def.modelName),
                            def.txdName, table.concat(def.flagsBits or {}, ","), def.drawDist, def.tIn, def.tOut
                        )
                    else
                        line = string.format(
                            '    <definition id="%s" zone="%s" col="%s" txd="%s" flags="%s" lodDistance="%s"></definition>\n',
                            def.modelName, def.zone, (changedCOL[def.modelName] or def.modelName),
                            def.txdName, table.concat(def.flagsBits or {}, ","), def.drawDist
                        )
                    end
                end
            end

            if not prep then
                if not invalid then
                    if f and line then
                        fileWrite(f, line)
                    end
                else
                    outputDebugString2("Notice: skipping IDE object due to invalid file: " .. def.modelName .. " - " .. reason, 2)
                end
            end
        end
    end

    if f then
        fileWrite(f, "</zoneDefinitions>\n")
        fileClose(f)
    end

    if not prep then
        outputDebugString("Successfully wrote .definition file: " .. definitionPath)
    end
end
