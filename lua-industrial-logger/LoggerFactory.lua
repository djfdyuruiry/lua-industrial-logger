local IdUtils = require "lua-industrial-logger.IdUtils"
local Logger = require "lua-industrial-logger.Logger"

local getLogger = function(name)
    local loggerConfig = require("lua-industrial-logger.LoggerConfiguration").getConfig()

    local loggerName = name and name or string.format("{logger-#%s}", IdUtils.generateNonUniqueId())
    local caller = debug.traceback()

    return Logger(loggerName, caller, loggerConfig)
end

return 
{
    getLogger = getLogger
}
