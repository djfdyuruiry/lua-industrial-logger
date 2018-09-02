local DEBUG_ENV_VAR_NAME = "LUA_LOG_DEBUG"

local debugLoggingEnabled = false

local log = function(message, ...)
    if not debugLoggingEnabled then
        return
    end

    local formattedMessage = (message):format(...)
    local callingFunctionInfo = debug.getinfo(2)

    local codeLocation = ("[%s:%s:%s]"):format(
        callingFunctionInfo.short_src,
        callingFunctionInfo.what,
        callingFunctionInfo.currentline
    )

    io.stderr:write(("%s - %s\r\n"):format(codeLocation, formattedMessage))
end

local setDebugLoggingEnabled = function(isEnabled)
    debugLoggingEnabled = isEnabled
end

local checkIfEnabledViaEnvironment = function()
    local debugEnvFlag = os.getenv(DEBUG_ENV_VAR_NAME)

    if debugEnvFlag == nil then
        return
    end
    
    debugEnvFlag = debugEnvFlag:lower()

    if debugEnvFlag == "true" then
        setDebugLoggingEnabled(true)
    end
end

checkIfEnabledViaEnvironment()

return
{
    log = log,
    setDebugLoggingEnabled = setDebugLoggingEnabled
}
