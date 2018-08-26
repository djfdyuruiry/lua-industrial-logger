local Levels = require "lua-industrial-logger.Levels"
local PatternBuilder = require "lua-industrial-logger.PatternBuilder"

local Logger = function(name, creator, loggerConfig)
    local patternBuilder = PatternBuilder(name, creator, loggerConfig)

    local writeToAppenders = function(logMessage)
        for _, appender in pairs(loggerConfig.appenders) do
            appender.append(logMessage)
        end
    end 

    local log = function(level, message, ...)
        local formattedMessage = string.format(message, ...):gsub("%%", "%%%%")

        if loggerConfig.appendNewlines then
            formattedMessage = formattedMessage .. "\n"
        end

        writeToAppenders(
            patternBuilder.buildLogMessageFromPattern(level, formattedMessage)
        )
    end

    local logError = function(level, message, err, ...)
        local formattedMessage = string.format(message, ...):gsub("%%", "%%%%")
    
        if loggerConfig.appendNewlines then
            formattedMessage = formattedMessage .. "\n"
        end

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
