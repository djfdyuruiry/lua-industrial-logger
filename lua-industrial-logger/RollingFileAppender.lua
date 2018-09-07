local DebugLogger = require "lua-industrial-logger.DebugLogger"
local FileAppender = require "lua-industrial-logger.FileAppender"
local FileUtils = require "lua-industrial-logger.FileUtils"
local OsUtils = require "lua-industrial-logger.OsUtils"
local StringUtils = require "lua-industrial-logger.StringUtils"

local compressionFormats = OsUtils.getSupportedCompressionFormats()

local RollingFileAppender = function(name, appenderConfig)
    local fileAppender = FileAppender(name, appenderConfig)
    local logFilePath = appenderConfig.logFilePath
    local rolloverConfig = appenderConfig.rollover
    local logFileName
    local maxLogFileSizeInBytes
    local backupFileFormat
    local backupFileExtension
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
            backupFileExtension = supportedFormats[potentialFormat].extension
        end

        if type(rolloverConfig.maxBackupFiles) ~= "number" then
            error(("'maxBackupFiles' is not a number or is missing for RollingFileAppender '%s'"):format(name)) 
        elseif rolloverConfig.maxBackupFiles < 1 then
            error(("'maxBackupFiles' for RollingFileAppender '%s' is incorrect, value must be greater than zero"):format(name))
        end

        logFileName = FileUtils.getFileName(logFilePath)
        maxLogFileSizeInBytes = rolloverConfig.maxFileSizeInKb * 1000
        maxBackupFiles = rolloverConfig.maxBackupFiles

        DebugLogger.log("validated appender config with backupFileFormat = '%s' and maxLogFileSizeInBytes = '%d' and maxBackupFiles = '%d'", backupFileFormat, maxLogFileSizeInBytes, maxBackupFiles)
    end

    validateConfig()

    local buildBackupFilePath = function(backupIndex, includeFileExtension)
        DebugLogger.log("build backup file path with logFilePath = '%s' and backupIndex = '%d' and includeFileExtension = '%s'", logFilePath, backupIndex, includeFileExtension)
    
        local backupFileName = StringUtils.concat(logFileName, "-", backupIndex)

        local backupFilePath = FileUtils.combinePaths(fileAppender.logFileDirectory, backupFileName)
        
        if includeFileExtension then
            backupFilePath = string.format("%s.%s", backupFilePath, backupFileExtension)
        end

        DebugLogger.log("build backup file path returning with backupFilePath = '%s'", backupFilePath)

        return backupFilePath
    end

    local getNextBackupFileIndex = function()
        DebugLogger.log("get next backup file index")

        for idx = 1, maxBackupFiles do
            local backupFilePath = buildBackupFilePath(idx, true)

            if not FileUtils.fileExists(backupFilePath) then
                DebugLogger.log("get next backup file index returning with idx = '%d'", idx)
                return idx
            end
        end
    end

    local rolloverLogBackups = function(backupFiles)
        DebugLogger.log("rolling over log file backups with backupFiles = '%s'", backupFiles)

        local oldestBackupFile
        local oldestBackupFileTimestamp = -1

        for _, backupFile in ipairs(backupFiles) do
            local fileTimestamp = OsUtils.getFileModificationTime(backupFile)

            if oldestBackupFileTimestamp == -1 or oldestBackupFileTimestamp > fileTimestamp then
                oldestBackupFile = backupFile
                oldestBackupFileTimestamp = fileTimestamp
            end
        end

        FileUtils.deleteFile(oldestBackupFile)
    end

    local checkIfMaxNumberOfLogBackupsArePresent = function()
        DebugLogger.log("checking if maximum number of backup files reached with logFileName = '%s' and backupFileExtension = '%s' and fileAppender.logFileDirectory = '%s'", logFileName, backupFileExtension, fileAppender.logFileDirectory)

        local backupFilesPattern = StringUtils.concat(logFileName, "-*.", backupFileExtension)
        local backupFilesPresent = OsUtils.getFilesForPattern(fileAppender.logFileDirectory, backupFilesPattern)

        maxLogBackupsArePresent = #backupFilesPresent >= maxBackupFiles
    
        DebugLogger.log("check for maximum number of backup files returning with maxLogBackupsArePresent = '%s'", maxLogBackupsArePresent)
        
        return maxLogBackupsArePresent, backupFilesPresent
    end

    local rolloverLogFile = function()
        DebugLogger.log("rolling over log file")

        local maxBackupFilePath = buildBackupFilePath(maxBackupFiles, true)
        local maxLogBackupsArePresent, backupFiles = checkIfMaxNumberOfLogBackupsArePresent()

        if maxLogBackupsArePresent then
            rolloverLogBackups(backupFiles)
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