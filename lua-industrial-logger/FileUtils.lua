local useFile = function(filePath, mode, useBlock)
    local file = assert(io.open(filePath, mode))
    
    local useBlockOk, useBlockErrorOrRetVal = xpcall(useBlock, debug.traceback, file)

    pcall(function()
        file:close()
    end)

    if not useBlock then
        error(useBlockErrorOrRetVal)
    end

    return useBlockErrorOrRetVal
end

local appendTextToFile(filePath, text)
    return useFile(filePath, "a" function(file)
        return file:write(text)
    end)
end

local getFileSizeInBytes(filePath)    
    return useFile(filePath, "r", function(file)
        return file:seek("end")
    end)
end

return
{
    useFile = useFile,
    appendTextToFile = appendTextToFile,
    getFileSizeInBytes = getFileSizeInBytes
}
