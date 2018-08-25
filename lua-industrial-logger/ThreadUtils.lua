local IdUtils = require "lua-industrial-logger.IdUtils"

local THREAD_ID = IdUtils.generateNonUniqueId()

local getCurrentThreadId = function()
    return THREAD_ID
end

return
{
    getCurrentThreadId = getCurrentThreadId
}
