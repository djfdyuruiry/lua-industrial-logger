local FileAppender = require "lua-industrial-logger.FileAppender"
local FileUtils = require "lua-industrial-logger.FileUtils"
local OsUtils = require "lua-industrial-logger.OsUtils"
local StringUtils = require "lua-industrial-logger.StringUtils"

local RollingFileAppender = function(name, appenderConfig)
    local fileAppender = FileAppender(name, appenderConfig)
    local logFilePath = appenderConfig.logFilePath
    local rolloverConfig = appenderConfig.rollover
    local maxLogFileSizeInBytes
    local backupFileFormat
    local backupFilePattern
    local maxBackupFiles

    local validateConfig = function()
        if type(rolloverConfig) ~= "table" then
            error(("'rollover' configuration table not supplied for Rolling FileAppender '%s'"):format(name))
        end
    
        if type(rolloverConfig.maxFileSizeInKb) ~= "number" then
            error(("'maxFileSizeInKb' is not a number or is missing for RollingFileAppender '%s'"):format(name))
        elseif rolloverConfig.maxFileSizeInKb < 1 then
            error(("'maxFileSizeInKb' for RollingFileAppender '%s' is incorrect, value must be greater than zero"):format(name))
        end

        if rolloverConfig.backupFileFormat ~= nil then
            if type(rolloverConfig.backupFileFormat) ~= "string" then
                error(("'backupFileFormat' specified for RollingFileAppender '%s' is not a string"):format(name))
            end

            local potentialFormat = rolloverConfig.backupFileFormat:lower()
            local supportedFormats = OsUtils.getSupportedCompressionFormats()

            if not supportedFormats[potentialFormat] then
                error(("'backupFileFormat' value '%s',specified for RollingFileAppender '%s', is not a supported format on the current OS"):format(potentialFormat, name))
            end

            backupFileFormat = potentialFormat
        end

        if StringUtils.isBlank(type(rolloverConfig.backupFilePattern)) then
            error(("'backupFilePattern' specified for RollingFileAppender '%s' is missing/blank"):format(name))
        end

        local dateOk, dateError = xpcall(function()
            os.date(rolloverConfig.backupFilePattern)
        end, debug.traceback, rolloverConfig.backupFilePattern)

        if not dateOk then
            error(("'backupFilePattern' specified for RollingFileAppender '%s' is invalid: %s"):format(name, dateError or "unknown error"))
        end

        if type(rolloverConfig.maxBackupFiles) ~= "number" then
            error(("'maxBackupFiles' is not a number or is missing for RollingFileAppender '%s'"):format(name)) 
        elseif rolloverConfig.maxBackupFiles < 1 then
            error(("'maxBackupFiles' for RollingFileAppender '%s' is incorrect, value must be greater than zero"):format(name))
        end

        maxLogFileSizeInBytes = rolloverConfig.maxFileSizeInKb * 1000
        backupFilePattern = rolloverConfig.backupFilePattern
        maxBackupFiles = rolloverConfig.maxBackupFiles
    end

    validateConfig()

    local rolloverLogFiles = function()
        local backupFileName = os.date(backupFilePattern)
        local backupFilePath = FileUtils.combinePaths(fileAppender.logFileDirectory, backupFileName)

        OsUtils.compressFilePath(logFilePath, backupFilePath, true, backupFileFormat)

        -- TODO: max backups logic
    end

    local append = function(level, message)
        fileAppender.append(level, message)

        local fileSizeInBytes = FileUtils.getFileSizeInBytes(logFilePath)

        if fileSizeInBytes > maxLogFileSizeInBytes then
            rolloverLogFiles()
        end
    end

    return
    {
        append = append
    }
end

return RollingFileAppender
