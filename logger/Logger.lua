local Levels = require "logger.Levels"
local PatternBuilder = require "logger.PatternBuilder"

local Logger = function(name, creator, loggerConfig)
    local patternBuilder = PatternBuilder(name, creator, loggerConfig)

    local writeToAppenders = function(logMessage)
        for _, appender in ipairs(loggerConfig.appenders) do
            appender.append(logMessage)
        end
    end 

    local log = function(level, message, ...)
        local formattedMessage = string.format(message, ...):gsub("%%", "%%%%")

        writeToAppenders(
            patternBuilder.buildLogMessageFromPattern(level, formattedMessage)
        )
    end

    local logError = function(level, message, err, ...)
        local formattedMessage = string.format(message, ...):gsub("%%", "%%%%")
    
        writeToAppenders(
            patternBuilder.buildLogMessageFromPattern(level, formattedMessage)
        )

        writeToAppenders(
            patternBuilder.buildLogMessageFromPattern(level, err)
        )
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
