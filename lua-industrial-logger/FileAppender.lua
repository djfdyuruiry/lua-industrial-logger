local FileUtils = require "lua-industrial-logger.FileUtils"
local OsUtils = require "lua-industrial-logger.OsUtils"
local StringUtils = require "lua-industrial-logger.StringUtils"

local FileAppender = function(name, loggerConfig)
    local logFileDirectory
    local logDirectoryCreated = false

    local validateConfig = function()
        if type(loggerConfig) ~= "table" then
            error(("Configuration table not supplied for FileAppender '%s'"):format(name))
        end

        if StringUtils.isBlank(loggerConfig.logFilePath) then
            error(("'logFilePath' specified for FileAppender '%s' is blank"):format(name))
        end

        logFileDirectory = FileUtils.getFileDirectory(loggerConfig.logFilePath)

        if not loggerConfig.createMissingDirectories and not OsUtils.directoryExists(logFileDirectory) then
            error(("Directory '%s' in 'logFilePath' for FileAppender '%s' is missing " ..
                "(set 'createMissingDirectories = true' to automatically create it)"):format(logFileDirectory, name))
        end
    end

    validateConfig()

    local append = function(logMessage)
        if loggerConfig.createMissingDirectories
          and not logDirectoryCreated
          and not OsUtils.directoryExists(logFileDirectory) then
            OsUtils.createDirectory(logFileDirectory)
            logDirectoryCreated = true
        end

        FileUtils.appendTextToFile(loggerConfig.logFilePath, logMessage)
    end

    return
    {
        append = append
    }
end

return FileAppender
