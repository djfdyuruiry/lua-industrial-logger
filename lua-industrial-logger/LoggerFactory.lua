local IdUtils = require "logger.IdUtils"
local Logger = require "logger.Logger"

local getLogger = function(name)
    local loggerConfig = require("logger.LoggerConfiguration").getConfig()

    local loggerName = name and name or string.format("{logger-#%s}", IdUtils.generateNonUniqueId())
    local caller = debug.traceback()

    return Logger(loggerName, caller, loggerConfig)
end

return 
{
    getLogger = getLogger
}
