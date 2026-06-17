-- Shared helpers: bitwise fallback, quaternion->Euler conversion, file copying,
-- day/night pairing and debug logging.

if not bit then
    bit = {}
end

if not bit.band then
    function bit.band(a, b)
        local r, m = 0, 1
        while a > 0 and b > 0 do
            -- Compare the lowest bit of both
            if (a % 2 == 1) and (b % 2 == 1) then
                r = r + m
            end
            a = math.floor(a / 2)
            b = math.floor(b / 2)
            m = m * 2
        end
        return r
    end
end

function math.sign(num)
    if num > 0 then
        return 1
    elseif num < 0 then
        return -1
    else
        return 0
    end
end

local identityMatrix = {
    [1] = {1, 0, 0},
    [2] = {0, 1, 0},
    [3] = {0, 0, 1},
}

local function quaternionTo3x3(x, y, z, w)
    local matrix3x3 = {[1] = {}, [2] = {}, [3] = {}}

    local symetricalMatrix = {
        [1] = {(-(y * y) - (z * z)), x * y, x * z},
        [2] = {x * y, (-(x * x) - (z * z)), y * z},
        [3] = {x * z, y * z, (-(x * x) - (y * y))},
    }

    local antiSymetricalMatrix = {
        [1] = {0, -z, y},
        [2] = {z, 0, -x},
        [3] = {-y, x, 0},
    }

    for i = 1, 3 do
        for j = 1, 3 do
            matrix3x3[i][j] = identityMatrix[i][j] + (2 * symetricalMatrix[i][j]) + (2 * w * antiSymetricalMatrix[i][j])
        end
    end

    return matrix3x3
end

local function getEulerAnglesFromMatrix(x1, y1, z1, x2, y2, z2, x3, y3, z3)
    local nz1, nz2, nz3
    nz3 = math.sqrt(x2 * x2 + y2 * y2)
    nz1 = -x2 * z2 / nz3
    nz2 = -y2 * z2 / nz3
    local vx = nz1 * x1 + nz2 * y1 + nz3 * z1
    local vz = nz1 * x3 + nz2 * y3 + nz3 * z3
    return math.deg(math.asin(z2)), -math.deg(math.atan2(vx, vz)), -math.deg(math.atan2(x2, y2))
end

-- Convert a quaternion to Euler angles (degrees).
function quatToEuler(x, y, z, w)
    local matrix = quaternionTo3x3(x, y, z, w)
    return getEulerAnglesFromMatrix(
        matrix[1][1], matrix[1][2], matrix[1][3],
        matrix[2][1], matrix[2][2], matrix[2][3],
        matrix[3][1], matrix[3][2], matrix[3][3]
    )
end

-- Converts an integer 'flagsValue' into a list of bit positions that are ON.
-- e.g. flagsValue=50 (binary 110010) -> {1, 4, 5}.
function parseFlagsToList(flagsValue)
    local list = {}
    for bitPos = 0, 31 do
        local mask = 2 ^ bitPos
        if bit.band(flagsValue, mask) ~= 0 then
            table.insert(list, bitPos)
        end
    end
    return list
end

metaList = {
    Textures    = {},
    Water       = {},
    Models      = {},
    Collisons   = {},
    Maps        = {},
    Definitions = {},
}

function getFileNameAndExtension(path)
    return path:match("([^/\\]+)%.([^%.\\/]+)$")
end

local function getContent(file, imgFile)
    if imgFile then
        return imgFile
    end
    local size = fileGetSize(file)
    local content = fileRead(file, size)
    fileClose(file)
    return content
end

-- Copies a model/texture/collision file from the input resource to the output.
--   dontCopy   : only validate that the source exists, don't write anything
--   ignoreMeta : skip registering the file in metaList
function copyFile(srcPath, dstPath, type, actualpath, dontCopy, ignoreMeta)
    local sName, ext = getFileNameAndExtension(actualpath)
    local nameExt = string.lower(sName .. "." .. ext)

    local fileValid = globalIMGFiles[nameExt] or fileExists(srcPath)

    if dontCopy then
        return fileValid and true or false
    end

    if not fileValid then
        return false, "Source file does not exist: " .. nameExt
    end

    -- Destination already written: just register it and move on.
    if fileExists(dstPath) then
        if type then
            if not ignoreMeta then
                metaList[type][actualpath] = true
            end
            return true
        end
    end

    local inFile = globalIMGFiles[nameExt] or fileOpen(srcPath)
    if not inFile then
        return false, "Failed to open source: " .. nameExt
    end

    if not ignoreMeta and type then
        metaList[type][actualpath] = true
    end

    local content = getContent(inFile, globalIMGFiles[nameExt])

    local outFile = fileCreate(dstPath)
    if not outFile then
        return false, "Failed to create destination: " .. dstPath
    end

    fileWrite(outFile, content)
    fileClose(outFile)

    return true
end

local nightNames = {"_nt", "_ng"}
local dayNames = {"_dy"}

local pair_day = {}
local pair_night = {}

-- Detects day/night model pairs by name suffix and returns the (timeIn, timeOut)
-- window once both halves of a pair have been seen.
function timeCalculator(name)
    for _, suffix in ipairs(nightNames) do
        if string.find(name, suffix) then
            local cleanedName = string.gsub(name, suffix, "")
            pair_day[cleanedName] = true
            if pair_night[cleanedName] then
                return 20, 6
            end
            return false
        end
    end

    for _, suffix in ipairs(dayNames) do
        if string.find(name, suffix) then
            local cleanedName = string.gsub(name, suffix, "")
            pair_night[cleanedName] = true
            if pair_day[cleanedName] then
                return 6, 20
            end
            return false
        end
    end
end

-- Logs to the MTA debug console and keeps a copy for debug.txt.
debugLines = {}
function outputDebugString2(message, level)
    outputDebugString(message, level)
    table.insert(debugLines, message)
end
