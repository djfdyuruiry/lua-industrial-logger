local ThreadUtils = require("logger.ThreadUtils")

local PATTERN_GENERATOR_MAP = 
{
    ["%{iso8601}d"] = function() 
        local utcDateTime = os.date("!*t")

        return string.format("%04d-%02d-%02dT%02d:%02d:%02dZ", 
            utcDateTime.year, utcDateTime.month, utcDateTime.day,
            utcDateTime.hour, utcDateTime.min, utcDateTime.sec)
    end,

    ["%d"] = function()
        return os.date("%c")
    end,

    ["%t"] = function() 
        return ThreadUtils.getCurrentThreadId() 
    end,

    ["%l"] = function(level)
        return string.upper(level)
    end,

    ["%n"] = function(_, loggerName, creator)
        return loggerName or creator
    end
}

return PATTERN_GENERATOR_MAP
