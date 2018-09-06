local DebugLogger = require "lua-industrial-logger.DebugLogger"
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
    local maxBackupFiles

    local validateConfig = function()
        DebugLogger.log("validating appender config")

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

        if type(rolloverConfig.maxBackupFiles) ~= "number" then
            error(("'maxBackupFiles' is not a number or is missing for RollingFileAppender '%s'"):format(name)) 
        elseif rolloverConfig.maxBackupFiles < 1 then
            error(("'maxBackupFiles' for RollingFileAppender '%s' is incorrect, value must be greater than zero"):format(name))
        end

        maxLogFileSizeInBytes = rolloverConfig.maxFileSizeInKb * 1000
        maxBackupFiles = rolloverConfig.maxBackupFiles

        DebugLogger.log("validated appender config with backupFileFormat = '%s' and maxLogFileSizeInBytes = '%d' and maxBackupFiles = '%d'", backupFileFormat, maxLogFileSizeInBytes, maxBackupFiles)
    end

    validateConfig()

    local buildBackupFilePath = function(backupIndex)
        DebugLogger.log("build backup file path with backupIndex = '%d'", backupIndex)
    
        local backupFileName = StringUtils.concat(logFilePath, "-", backupIndex)

        local backupFilePath = FileUtils.combinePaths(fileAppender.logFileDirectory, backupFileName)

        DebugLogger.log("build backup file path returning with backupFilePath = '%s'", backupFilePath)

        return backupFilePath
    end

    local getNextBackupFileIndex = function()
        DebugLogger.log("get next backup file index")

        for idx = 1, maxBackupFilePath do
            local backupFilePath = buildBackupFilePath(idx)

            if not FileUtils.fileExists(backupFile) then
                DebugLogger.log("get next backup file index returning with idx = '%d'", idx)
                return idx
            end
        end
    end

    local rolloverLogBackups = function(maxBackupFilePath)
        DebugLogger.log("rolling over log file backups with maxBackupFilePath = '%s'", maxBackupFilePath)

        FileUtils.deleteFile(maxBackupFilePath)

        for idx = maxBackupFiles - 1, 1, -1 do
            local backupFilePath = buildBackupFilePath(idx)

            if FileUtils.fileExists(backupFile) then
                local newBackupFilePath = buildBackupFilePath(idx + 1)

                OsUtils.moveFile(backupFilePath, newBackupFilePath)
            end
        end
    end

    local rolloverLogFile = function()
        DebugLogger.log("rolling over log file")

        local maxBackupFilePath = buildBackupFilePath(maxBackupFiles)

        if FileUtils.fileExists(maxBackupFilePath) then
            DebugLogger.log("rolling over log backups due to number of backup files reaching max with maxBackupFilePath = '%s'", maxBackupFilePath)
            rolloverLogBackups(maxBackupFilePath)
        end

        local backupFilePath = buildBackupFilePath(getNextBackupFileIndex())

        DebugLogger.log("backing up log file with logFilePath = '%s' and backupFilePath = '%s' and backupFileFormat = '%s'", logFilePath, backupFilePath, backupFileFormat)

        OsUtils.compressFilePath(logFilePath, backupFilePath, true, backupFileFormat)
    end

    local append = function(level, message)
        fileAppender.append(level, message)

        local fileSizeInBytes = FileUtils.getFileSizeInBytes(logFilePath)

        if fileSizeInBytes > maxLogFileSizeInBytes then
            rolloverLogFile()
        end
    end

    return
    {
        append = append
    }
end

return RollingFileAppender
