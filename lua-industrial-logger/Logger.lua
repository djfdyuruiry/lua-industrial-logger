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

    local isLogLevelAccepted = function(config, configName, level)
        if type(config) ~= "table" then
            return nil
        end

        local levelAccepted = nil
        
        if type(config.filter) == "function" then
            local filterStatus, filterError = xpcall(function()
                levelAccepted = (levelAccepted == nil and true or levelAccepted) and config.filter(level)
            end, debug.traceback)

            if not filterStatus then
                error(("Error applying filter in config '%s': %s"):format(configName, filterError))
            end
        else
            if type(config.minLevel) == "number" then
                levelAccepted = (levelAccepted == nil and true or levelAccepted) and level >= config.minLevel
            end
            
            if type(config.maxLevel) == "number" then
                levelAccepted = (levelAccepted == nil and true or levelAccepted) and level <= config.maxLevel
            end
        end
        
        return levelAccepted
    end

    local writeToAppenders = function(level, logMessage, ...)
        local levelValue = Levels.parse(level)
        local configAcceptedLevel = isLogLevelAccepted(loggerConfig, "loggerConfig", levelValue)
        local formattedMessage, defaultPatternMessage 

        for appenderName, appender in pairs(loggerConfig.appenders) do
            local appenderAcceptedLevel = isLogLevelAccepted(appender.config, appenderName, levelValue)

            if appenderAcceptedLevel == nil then
                appenderAcceptedLevel = configAcceptedLevel
            end

            if appenderAcceptedLevel then
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
            __index = function(self, level)
                Levels.parse(level)

                if level:lower() == "off" then
                    return nil
                end

                return function (message, ...)
                    log(level, message, ...)
                end
            end
        }
    )
end

return Logger
