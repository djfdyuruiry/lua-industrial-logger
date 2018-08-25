local DEFAULT_COMPRESSION_FORMAT = "tar"
local REDIRECT_OUTPUT = "> /dev/null"

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
            os.execute(("zip -%s9 '%s' '%s' %s"):format(removeFilesFlag, archiveName, file, REDIRECT_OUTPUT)), 
            ("error creating zip archive '%s' for file '%s'"):format(archiveName, file)
        )
    end
end

local getUnixTarCompressionUtil = function()
    assertCommandAvailable("tar")

    return function(file, archiveName, removeFiles)
        local removeFilesFlag = removeFiles and "--remove-files" or ""

        assert(
            os.execute(("env GZIP=-9 tar -czf '%s.gz.tar' '%s' %s %s"):format(archiveName, file, removeFilesFlag, REDIRECT_OUTPUT)), 
            ("error creating tar archive '%s' for file '%s'"):format(archiveName, file)
        )
    end
end

local osIsUnixLike = function()
    return package.config:sub(1, 1) == "/"
end

local getCompressionUtil = function(format)
    format = format or DEFAULT_COMPRESSION_FORMAT

    if not osIsUnixLike() then
        error("compression not supported on non unix OS")
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

return
{
    osIsUnixLike = osIsUnixLike,
    assertCommandAvailable = assertCommandAvailable,
    getCompressionUtil = getCompressionUtil,
    compressFilePath = compressFilePath
}
