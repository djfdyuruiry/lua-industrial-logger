local Levels = require "lua-industrial-logger.Levels"
local PatternBuilder = require "lua-industrial-logger.PatternBuilder"

local Logger = function(name, creator, loggerConfig)
    local patternBuilder = PatternBuilder(name, creator)
    local defaultPattern = loggerConfig.pattern

    local writeToAppenders = function(level, logMessage, ...)
        local formattedMessage = string.format(logMessage, ...):gsub("%%", "%%%%")
    
        if loggerConfig.appendNewlines then
            formattedMessage = formattedMessage .. "\n"
        end

        local defaultPatternMessage = patternBuilder.buildLogMessageFromPattern(defaultPattern, level, formattedMessage)

        for _, appender in pairs(loggerConfig.appenders) do
            local message = defaultPatternMessage

            if type(appender.config) == "table" and appender.config.pattern then
                message = patternBuilder.buildLogMessageFromPattern(appender.config.pattern, level, formattedMessage)
            end

            appender.append(message)
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
                if index:lower() == "off" then
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
