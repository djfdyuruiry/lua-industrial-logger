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
        os.execute(("command -v %s %s"):format(command, REDIRECT_OUTPUT)), 
        ("unable to find 'tar' command"):format(command)
    )
end

local getUnixZipCompressionUtil = function()
    assertCommandAvailable("zip")

    return function(file, archiveName, removeFiles)
        local removeFilesFlag = removeFiles and "m" or ""

        assert(
            os.execute(("zip -%s9 '%s' '%s' %s"):format(removeFilesFlag, archiveName, file, getOutputRedirectString())), 
            ("error creating zip archive '%s' for file '%s'"):format(archiveName, file)
        )
    end
end

local getUnixTarCompressionUtil = function()
    assertCommandAvailable("tar")

    return function(file, archiveName, removeFiles)
        local removeFilesFlag = removeFiles and "--remove-files" or ""

        assert(
            os.execute(("env GZIP=-9 tar -czf '%s.gz.tar' '%s' %s %s"):format(archiveName, file, removeFilesFlag, getOutputRedirectString())), 
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

return
{
    osIsUnixLike = osIsUnixLike,
    assertCommandAvailable = assertCommandAvailable,
    getCompressionUtil = getCompressionUtil,
    compressFilePath = compressFilePath,
    directoryExists = directoryExists,
    createDirectory = createDirectory
}
