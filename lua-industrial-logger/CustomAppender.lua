local DebugLogger = require "lua-industrial-logger.DebugLogger"

local CustomAppender = function(name, appenderConfig)
    local config = appenderConfig or {}

    DebugLogger.log("Loaded CustomAppender with name = '%s' and config = '%s'", name, tostring(config))

    local append = function(level, logMessage)
    end
    
    return
    {
        append = append,
        name = name,
        config = config
    }
end

return CustomAppender
