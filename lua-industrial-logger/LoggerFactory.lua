local DebugLogger = require "lua-industrial-logger.DebugLogger"
local IdUtils = require "lua-industrial-logger.IdUtils"
local Logger = require "lua-industrial-logger.Logger"

local getLogger = function(name)
    local loggerConfig = require("lua-industrial-logger.LoggerConfiguration").getConfig()

    local caller = debug.getinfo(2).short_src
    local loggerName = name and name or caller or string.format("{logger-#%s}", IdUtils.generateNonUniqueId())

    DebugLogger.log("Building logger with name = '%s' and caller = '%s'", loggerName, caller)

    return Logger(loggerName, caller, loggerConfig)
end

return 
{
    getLogger = getLogger
}
