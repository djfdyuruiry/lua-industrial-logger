local Levels = require "lua-industrial-logger.Levels"
local PatternBuilder = require "lua-industrial-logger.PatternBuilder"

local Logger = function(name, creator, loggerConfig)
    local patternBuilder = PatternBuilder(name, creator)
    local defaultPattern = loggerConfig.pattern

    local buildLogMessageFromAppenderPattern = function(appender, level, formattedMessage)
        if type(appender.config) == "table" and appender.config.pattern then
            message = patternBuilder.buildLogMessageFromPattern(appender.config.pattern, level, formattedMessage)
        end
    end

    local buildLogMessageWithPattern = function(level, logMessage)
        return patternBuilder.buildLogMessageFromPattern(defaultPattern, level, logMessage)
    end

    local formatMessage = function(logMessage, ...)
        local formattedMessage = string.format(logMessage, ...):gsub("%%", "%%%%")

        if loggerConfig.appendNewlines then
            formattedMessage = formattedMessage .. "\n"
        end

        return formattedMessage
    end

    local logLevelAcceptedByAppender = function(appender, level)

        
        return false
    end

    local logLevelAccepted = function(config, configName, level)
        if type(config) ~= "table" then
            return false
        end

        local levelAccepted = nil
        
        if type(config.filter) == "function" then
            local filterStatus, filterError = xpcall(function()
                levelAccepted = (levelAccepted == nil and true or levelAccepted) and config.filter(level)
            end, debug.traceback)

            if not filterStatus then
                io.error:write(("Error applying filter '%s': %s"):format(configName, filterError))
            end
        else
            if type(config.minLevel) == "number" then
                levelAccepted = (levelAccepted == nil and true or levelAccepted) and level >= config.minLevel
            end
            
            if type(config.maxLevel) == "number" then
                levelAccepted = (levelAccepted == nil and true or levelAccepted) and level <= config.maxLevel
            end
        end
        
        return (levelAccepted == nil and false or levelAccepted)
    end

    local writeToAppenders = function(level, logMessage, ...)
        local formattedMessage
        local defaultPatternMessage 
        local levelValue = Levels[level:upper()]

        for appenderName, appender in pairs(loggerConfig.appenders) do
            if logLevelAccepted(loggerConfig, "loggerConfig", levelValue)
                or logLevelAccepted(appender.config, appenderName, levelValue) then
                formattedMessage = formattedMessage or formatMessage(logMessage, ...)
                defaultPatternMessage = defaultPatternMessage or buildLogMessageWithPattern(level, formattedMessage)

                local message = buildLogMessageFromAppenderPattern(appender, level, formattedMessage) or defaultPatternMessage

                appender.append(message)
            end
        end
    end 

    local log = function(level, message, ...)
        writeToAppenders(level, message, ...)
    end

    local logError = function(level, message, err, ...)
        writeToAppenders(level, message, ...)
        writeToAppenders(level, err, ...)
    end

    return setmetatable(
        {
            log = log,
            logError = logError
        },
        {
            __index = function(self, index)
                if type(index) ~= "string" or index:lower() == "off" or not Levels[index:upper()] then
                    return nil
                end

                return function (message, ...)
                    log(index, message, ...)
                end
            end
        }
    )
end

return Logger
