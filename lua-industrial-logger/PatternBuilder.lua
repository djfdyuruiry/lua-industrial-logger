local DebugLogger = require "lua-industrial-logger.DebugLogger"
local PatternGeneratorMap = require("lua-industrial-logger.PatternGeneratorMap")
local StringUtils = require ("lua-industrial-logger.StringUtils")

local PatternBuilder = function(loggerName, creator)
    local buildLogMessageFromPattern = function (pattern, level, message)
        DebugLogger.log("building message from pattern with pattern = '%s' and level = '%s' and message = '%s'", pattern, level, message)

        local logMessage = pattern

        for pattern, replacementGenerator in pairs(PatternGeneratorMap) do
            logMessage = StringUtils.replacePatternIfPresent(
                logMessage,
                pattern,
                replacementGenerator,
                level,
                loggerName,
                creator
            )
        end

        return StringUtils.replacePatternIfPresent(logMessage, "%m", message)
    end

    return
    {
        buildLogMessageFromPattern = buildLogMessageFromPattern
    }
end

return PatternBuilder
