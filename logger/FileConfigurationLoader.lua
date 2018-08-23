local load = load or loadstring
local LoggerFactory = require "logger.LoggerFactory"
local StringUtils = require "logger.StringUtils"

local CONFIG_FILE_ENV_VAR = "LUA_LOG_CFG_FILE"
local DEFAULT_CONFIG_FILE_PATH = "logger.lua.config"

local executeConfigLoader = function(configLoader)
    local fileConfig, configLoaderError = configLoader()

    if not fileConfig or configLoaderError then
        error(
            string.format("Error loading logger configuration from file at path '%s': %s\nConfig Lua:\n%s",
                configFilePath, configLoaderError or "unknown error occurred", configFileLua)
        )
    end

    if type(fileConfig) ~= "table" then
        error(
            string.format("Unable to load logger config from file at path '%s': %s defined by config, please declare a table instead", 
                configFilePath, type(fileConfig))
        )
    end

    return fileConfig
end

local buildConfigLoaderForFile = function(configFile)
    local configFileLua = configFile:read("*all")

    pcall(function() configFile:close() end)
    
    local configLua = string.format("return %s", configFileLua)
    local configLoader, luaLoadError = load(configLua)

    if not configLoader or luaLoadError then
        error(
            string.format("Unable to parse logger config lua from file at path '%s': %s\nConfig Lua:\n%s",
                configFilePath, luaLoadError or "unknown error occurred", configFileLua)
        )
    end

    return configLoader, configFileLua
end

local openConfigFile = function(configFilePath)
    local configFile, configFileError = io.open(configFilePath)

    if configFileError and configFilePath == DEFAULT_CONFIG_FILE_PATH then
        return true
    end
    
    if not configFile or configFileError then
        error(string.format("Unable to load logger config from file at path '%s': %s", configFilePath, configFileError))
    end

    return false, configFile
end

local getConfigFilePath = function()
    local envConfigFilePath = os.getenv(CONFIG_FILE_ENV_VAR)

    if envConfigFilePath and StringUtils.isBlank(envConfigFilePath) then
        error(string.format("Unable to load logger config file path from environment variable '%s': value is blank", CONFIG_FILE_ENV_VAR))
    end

    return envConfigFilePath
end

local loadConfigFromFile = function(postLoadConfigCallback)
    if type(postLoadConfigCallback) ~= "function" then
        error("parameter 'postLoadConfigCallback' passed to 'loadConfigFromFile' is not a function")
    end

    local configFilePath = getConfigFilePath() or DEFAULT_CONFIG_FILE_PATH
    local noFileToLoad, configFile = openConfigFile(configFilePath)

    if noFileToLoad then
        return false
    end

    local configLoader, configFileLua = buildConfigLoaderForFile(configFile)
    local fileConfig = executeConfigLoader(configLoader)

    postLoadConfigCallback(fileConfig)

    LoggerFactory.getLogger("FileConfigurationLoader")
        .debug("Loaded logger configuration from file at path '%s': \nConfiguration Lua:\n%s", configFilePath, configFileLua)
end

return
{
    load = loadConfigFromFile
}
