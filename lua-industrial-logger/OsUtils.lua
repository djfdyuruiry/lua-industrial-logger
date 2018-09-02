local StringUtils = require "lua-industrial-logger.StringUtils"

local DIRECTORY_SEPERATOR = package.config:sub(1, 1)
local DEFAULT_COMPRESSION_FORMAT = "tar"
local REDIRECT_OUTPUT = "> %s"
local REDIRECT_ALL_OUTPUT = "> %s 2>&1"

local osIsUnixLike = function()
    return DIRECTORY_SEPERATOR == "/"
end

local getOutputRedirectString = function(redirectAllStreams)
    local nullPath = osIsUnixLike() and "/dev/null" or "NUL"

    if redirectAllStreams then
        return REDIRECT_ALL_OUTPUT:format(nullPath)
    end

    return REDIRECT_OUTPUT:format(nullPath)
end

local assertCommandAvailable = function(command)
    assert(
        os.execute(("command -v %s %s"):format(command, getOutputRedirectString(true))), 
        ("unable to find 'tar' command"):format(command)
    )
end

local getUnixZipCompressionUtil = function()
    assertCommandAvailable("zip")

    return function(file, archiveName, removeFiles)
        local removeFilesFlag = removeFiles and "m" or ""

        assert(
            os.execute(("zip -%s9 '%s.zip' '%s' %s"):format(removeFilesFlag, archiveName, file, getOutputRedirectString())), 
            ("error creating zip archive '%s' for file '%s'"):format(archiveName, file)
        )
    end
end

local getUnixTarCompressionUtil = function()
    assertCommandAvailable("tar")

    return function(file, archiveName, removeFiles)
        local removeFilesFlag = removeFiles and "--remove-files" or ""

        assert(
            os.execute(("env GZIP=-9 tar -czf '%s.gz.tar' '%s' %s %s"):format(archiveName, file, removeFilesFlag, getOutputRedirectString(true))), 
            ("error creating tar archive '%s' for file '%s'"):format(archiveName, file)
        )
    end
end

local getCompressionUtil = function(format)
    format = format or DEFAULT_COMPRESSION_FORMAT

    if not osIsUnixLike() then
        error("file compression only supported on unix like operating systems")
    end

    if format == "tar" then
        return getUnixTarCompressionUtil()
    elseif format == "zip" then
        return getUnixZipCompressionUtil()
    end

    error(("unknown compression format: %s'"):format(format))
end

local compressFilePath = function(filePath, archiveName, removeFiles, compressionFomat)
    local compressionUtil = getCompressionUtil(compressionFomat)

    compressionUtil(filePath, archiveName, removeFiles)
end

local getSupportedCompressionFormats = function()
    if osIsUnixLike() then
        return {tar = true, zip = true}
    end

    return {}
end

local directoryExists = function(directoryPath)
    local commandStatus, _, exitCode = os.execute(([[cd "%s" %s]]):format(directoryPath, getOutputRedirectString(true)))

    return commandStatus and exitCode == 0
end

local createDirectory = function(directoryPath)
    local createMissingPathsFlag = ""

    if osIsUnixLike() then
        createMissingPathsFlag = "-p"
    end

    assert(
        os.execute(([[mkdir %s "%s" %s]]):format(createMissingPathsFlag, directoryPath, getOutputRedirectString())), 
        ("error creating directory at path: %s"):format(directoryPath)
    )
end

local getFileModificationTimeCommand = function(filePath)
    if osIsUnixLike() then
        return ([[date -r "%s" +%%s]]):format(filePath)
    end

    return ([[for %%f in ("%s") do @echo %%~tf]]):format(filePath)
end

local getFileModificationTime = function(filePath)getFileModificationTimeCommand(filePath)
    local modificationTimeCommand = getFileModificationTimeCommand(filePath)
    local dateProc, err = io.popen(modificationTimeCommand)

    if not dateProc or err then
        error(("Error getting modification time for file '%s': %s"):format(filePath, err or "unknown error"))
    end

    local utcTimestamp = dateProc:read("*a")

    pcall(function()
        dateProc:close()
    end)

    return StringUtils.trim(utcTimestamp)
end

local getFileListingCommand = function(directoryPath, filePattern)
    if osIsUnixLike() then
        return ([[echo "%s"/%s]]):format(directoryPath, filePattern)
    end

    return ([[for %%f in ("%s\%s") do @echo | set /p=%%f]]):format(directoryPath, filePattern)
end

local getFilesForPattern = function(directoryPath, filePattern)
    local fileListingCommand = getFileListingCommand(directoryPath, filePattern)
    local listProc, err = io.popen(fileListingCommand)

    if not listProc or err then
        error(("Error listing files in directory '%s' using pattern '%s': %s"):format(directoryPath, filePattern, err or "unknown error"))
    end

    local filesString = listProc:read("*a")

    return StringUtils.explodeString(filesString, "%S+")
end

local getMoveFileCommand = function()
    if osIsUnixLike() then
        return [[mv -f "%s" "%s"]]
    else
        return [[move /Y "%s" "%s"]]
    end
end

local moveFile = function(originalFilePath, newFilePath)
    local moveFileCommand = getMoveFileCommand():format(originalFilePath, newFilePath)
    
    assert(os.execute(moveFileCommand))
end

return
{
    osIsUnixLike = osIsUnixLike,
    assertCommandAvailable = assertCommandAvailable,
    getCompressionUtil = getCompressionUtil,
    compressFilePath = compressFilePath,
    getSupportedCompressionFormats = getSupportedCompressionFormats,
    directoryExists = directoryExists,
    createDirectory = createDirectory,
    getFileModificationTime = getFileModificationTime,
    getFilesForPattern = getFilesForPattern,
    moveFile = moveFile
}
