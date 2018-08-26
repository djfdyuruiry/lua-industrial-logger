require "lua-industrial-logger.polyfills.loadstring"

local LoggerFactory = require "lua-industrial-logger.LoggerFactory"
local StringUtils = require "lua-industrial-logger.StringUtils"

local CONFIG_LOADER_ENV_VAR = "LUA_LOG_CFG_LOADER"
local DEFAULT_PATTERN = "%{iso8601}d [%t] %l %n - %m"
local DEFAULT_CONFIG_LOADER = "lua-industrial-logger.FileConfigurationLoader"

local loggerConfig = nil

local setConfig = function(config)
    if not config then
        error("nil argument 'config' passed to setConfig")
    end

    local appenders = {}

    for appenderName, appenderConfig in pairs(config.appenders) do
        appenders[appenderName] = require(appenderConfig.module)(appenderName, appenderConfig.config)
    end

    config.appenders = appenders

    loggerConfig = config
end

local initConfig = function(configFieldsToSet)
    if configFieldsToSet and type(configFieldsToSet) ~= "table" then
        error("optional argument 'configFieldsToSet' passed to 'loadConfig' requires a table value")
    end

    local config = {
        pattern = DEFAULT_PATTERN,
        appendNewlines = true,
        appenders =
        {
            console =
            {
                module = "lua-industrial-logger.ConsoleAppender"
            }
        }
    }

    if configFieldsToSet then
        for field, value in pairs(configFieldsToSet) do
            config[field] = value
        end
    end

    setConfig(config)
end

local executeConfigLoader = function()
    local envConfigLoader = os.getenv(CONFIG_LOADER_ENV_VAR)

    if envConfigLoader and StringUtils.isBlank(envConfigLoader) then
        error(string.format("Unable to get logger config loader from environment variable '%s': value is blank", CONFIG_LOADER_ENV_VAR))
    end

    local configLoader = envConfigLoader or DEFAULT_CONFIG_LOADER
    local configLoaderLua = string.format("return require('%s')", configLoader)

    local getConfigLoader, loadError = loadstring(configLoaderLua)

    if not getConfigLoader or loadError then
        error(loadError or "unknown error occurred")
    end

    getConfigLoader().load(initConfig)
end

local initConfigIfNeeded = function()
    if loggerConfig then
        return
    end

    local _, loadError = xpcall(executeConfigLoader, debug.traceback)

    if loggerConfig then
        return
    end

    initConfig()

    local logger = LoggerFactory.getLogger("LoggerConfiguration")

    if loadError then
        logger.error("Error loading logger configuration: %s\nAs a fallback, logger configuration has been loaded from defaults", 
            loadError)

        return
    end

    logger.debug("Loaded logger configuration from defaults")
end

local getConfig = function()
    initConfigIfNeeded()

    return loggerConfig
end

return 
{
    getConfig = getConfig,
    setConfig = setConfig,
    initConfigIfNeeded = initConfigIfNeeded
}
