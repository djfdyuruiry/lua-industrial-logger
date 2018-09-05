local setfenv = require "lua-industrial-logger.polyfills.setfenv"

local DebugLogger = require "lua-industrial-logger.DebugLogger"
local Levels = require "lua-industrial-logger.Levels"

local appenderCreator = function(config, defaultName, module)
    DebugLogger.log("appender creator declared with defaultName = '%s' and module = '%s'", defaultName, module)

    return function(name)
        name = name or defaultName

        config.appenders = config.appenders or {}
        config.appenders[name] =
        {
            module = module
        }

        DebugLogger.log("appender defined in config DSL with name = '%s' and module = '%s'", name, module)

        return function(appenderConfig)
            config.appenders[name].config = appenderConfig

            DebugLogger.log("config for appender defined in config DSL for appender with name = '%s' and config = '%s'", name, appenderConfig)
        end
    end
end

local runAppenderGenerators = function(appenderGenerators)
    if type(appenderGenerators) ~= "table" then
        return
    end

    DebugLogger.log("appender generators defined in config DSL")

    for _, appenderGenerator in ipairs(appenderGenerators) do
        if type(appenderGenerator) == "function" then
            appenderGenerator()
        end
    end
end

local configPropertySetter = function(config, propertyName)
    DebugLogger.log("config property setter declared in config DSL with config = '%s' and propertyName = '%s'", config, propertyName)

    return function(value)
        config[propertyName] = value

        DebugLogger.log("config property value declared in config DSL with config = '%s' and propertyName = '%s' and value = '%s'", config, propertyName, value)
    end
end

local syntaxSugar = function() end

local buildConfigUsingLoaderDsl = function(loaderFunction)
    local config = {}
    local dslEnv = {
        config = syntaxSugar,
        pattern = configPropertySetter(config, "pattern"),
        minLevel = configPropertySetter(config, "minLevel"),
        maxLevel = configPropertySetter(config, "maxLevel"),
        filter = configPropertySetter(config, "filter"),
        appenders = runAppenderGenerators,
        appender = function(module)
            return appenderCreator(config, module)
        end,
        console = appenderCreator(config, "console", "lua-industrial-logger.ConsoleAppender"),
        file = appenderCreator(config, "file", "lua-industrial-logger.FileAppender"),
        rollingFile = appenderCreator(config, "rollingFile", "lua-industrial-logger.RollingFileAppender")
    }

    for level, levelAsInt in pairs(Levels) do
        dslEnv[level] = levelAsInt
    end

    setfenv(loaderFunction, dslEnv)

    local _, err = loaderFunction()

    return config, err
end

return
{
    buildConfigUsingLoaderDsl = buildConfigUsingLoaderDsl
}
