local DIRECTORY_SEPERATOR = package.config:sub(1, 1)
local LAST_SEPERATOR_REGEX = ([[^.*()%s]]):format(DIRECTORY_SEPERATOR)

local useFile = function(filePath, mode, useBlock)
    local file = assert(io.open(filePath, mode))
    
    local useBlockOk, useBlockErrorOrRetVal = xpcall(useBlock, debug.traceback, file)

    pcall(function()
        file:close()
    end)

    if not useBlockOk then
        error(useBlockErrorOrRetVal)
    end

    return useBlockErrorOrRetVal
end

local appendTextToFile = function(filePath, text)
    return useFile(filePath, "a", function(file)
        return file:write(text)
    end)
end

local getFileSizeInBytes = function(filePath)    
    return useFile(filePath, "r", function(file)
        return file:seek("end")
    end)
end

local fileExists = function(filePath)
    local file, fileOpenError = io.open(filePath)

    pcall(function()
        file:close()
    end)

    return file and not fileOpenError
end

local getFileDirectory = function(filePath)
    local lastSeperatorIndex = filePath:match(LAST_SEPERATOR_REGEX)

    if not lastSeperatorIndex then
        return "./"
    end

    return filePath:sub(0, lastSeperatorIndex)
end

return
{
    useFile = useFile,
    appendTextToFile = appendTextToFile,
    getFileSizeInBytes = getFileSizeInBytes,
    fileExists = fileExists,
    getFileDirectory = getFileDirectory
}
