local DebugLogger = require "lua-industrial-logger.DebugLogger"
local IdUtils = require "lua-industrial-logger.IdUtils"

local THREAD_ID = IdUtils.generateNonUniqueId()

local getCurrentThreadId = function()
    DebugLogger.log("getting current thread id with THREAD_ID = '%s'", THREAD_ID)
    return THREAD_ID
end

return
{
    getCurrentThreadId = getCurrentThreadId
}
