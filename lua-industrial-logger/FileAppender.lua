local FileUtils = require "lua-industrial-logger.FileUtils"
local OsUtils = require "lua-industrial-logger.OsUtils"
local StringUtils = require "lua-industrial-logger.StringUtils"

local FileAppender = function(name, config)
    local logFileDirectory
    local logDirectoryCreated = false

    local validateConfig = function()
        if type(config) ~= "table" then
            error(("Configuration table not supplied for FileAppender '%s'"):format(name))
        end

        if StringUtils.isBlank(config.logFilePath) then
            error(("'logFilePath' specified for FileAppender '%s' is missing/blank"):format(name))
        end

        logFileDirectory = FileUtils.getFileDirectory(config.logFilePath)

        if not config.createMissingDirectories and not OsUtils.directoryExists(logFileDirectory) then
            error(("Directory '%s' in 'logFilePath' for FileAppender '%s' is missing " ..
                "(set 'createMissingDirectories = true' to automatically create it)"):format(logFileDirectory, name))
        end
    end

    validateConfig()

    local append = function(level, logMessage)
        if config.createMissingDirectories
          and not logDirectoryCreated
          and not OsUtils.directoryExists(logFileDirectory) then
            OsUtils.createDirectory(logFileDirectory)
            logDirectoryCreated = true
        end

        FileUtils.appendTextToFile(config.logFilePath, logMessage)
    end

    return
    {
        append = append,
        config = config
    }
end

return FileAppender
