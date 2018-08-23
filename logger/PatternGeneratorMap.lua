local ThreadUtils = require("logger.ThreadUtils")

local PATTERN_GENERATOR_MAP = {}

PATTERN_GENERATOR_MAP["%{iso8601}d"] = function() 
    local utcDateTime = os.date("!*t")

    return string.format("%04d-%02d-%02dT%02d:%02d:%02dZ", 
        utcDateTime.year, utcDateTime.month, utcDateTime.day,
        utcDateTime.hour, utcDateTime.min, utcDateTime.sec)
end

PATTERN_GENERATOR_MAP["%d"] = function()
    return os.date("%c")
end

PATTERN_GENERATOR_MAP["%t"] = function() 
    return ThreadUtils.getCurrentThreadId() 
end

PATTERN_GENERATOR_MAP["%l"] = function(level)
    return string.upper(level)
end

PATTERN_GENERATOR_MAP["%n"] = function(_, loggerName, creator)
    return loggerName or creator
end

return PATTERN_GENERATOR_MAP
