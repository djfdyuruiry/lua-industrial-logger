local PatternGeneratorMap = require("logger.PatternGeneratorMap")
local StringUtils = require ("logger.StringUtils")

local PatternBuilder = function(loggerName, creator, loggerConfig)
    local buildLogMessageFromPattern = function (level, message)
        local logMessage = loggerConfig.pattern

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
