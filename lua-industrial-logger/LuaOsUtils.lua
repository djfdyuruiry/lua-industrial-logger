local lfs = require "lfs"

local NativeOsUtils = require "lua-industrial-logger.NativeOsUtils"
local StringUtils = require "lua-industrial-logger.StringUtils"

local directoryExists = function(directoryPath)
    local directoryPathAttributes, pathError = lfs.attributes(directoryPath)

    return not pathError and directoryPathAttributes.mode == "directory"
end

local createDirectory = function(directoryPath)
    assert(lfs.mkdir(directoryPath))
end

local getFileModificationTime = function(filePath)
    return assert(lfs.attributes(filePath)).modification
end

local getFilesForPattern = function(directoryPath, filePattern)
    filePattern = StringUtils.replacePatternIfPresent(filePattern, "*", ".*")
    filePattern = StringUtils.replacePatternIfPresent(filePattern, ".", "[.]")

    matchingFiles = {}

    for file in lfs.dir(directoryPath) do
        if file ~= "." and file ~= ".." then
            if file:match(filePattern) then
                table.insert(matchingFiles, file)
            end
        end
    end

    return matchingFiles
end

return
{
    compressFilePath = NativeOsUtils.compressFilePath,
    getSupportedCompressionFormats = NativeOsUtils.getSupportedCompressionFormats,
    directoryExists = directoryExists,
    createDirectory = createDirectory,
    getFileModificationTime = getFileModificationTime,
    getFilesForPattern = getFilesForPattern,
    moveFile = NativeOsUtils.moveFile
}
