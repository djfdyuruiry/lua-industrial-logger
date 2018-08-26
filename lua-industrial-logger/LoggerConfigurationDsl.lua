require "lua-industrial-logger.polyfills.setfenv"

local Levels = require "lua-industrial-logger.Levels"

local appenderCreator = function(config, defaultName, module)
    return function(name)
        name = name or defaultName

        config.appenders = config.appenders or {}
        config.appenders[name] =
        {
            module = module
        }

        return function(appenderConfig)
            config.appenders[name].config = appenderConfig
        end
    end
end

local runAppenderGenerators = function(appenderGenerators)
    if type(appenderGenerators) ~= "table" then
        return
    end

    for _, appenderGenerator in ipairs(appenderGenerators) do
        if type(appenderGenerator) == "function" then
            appenderGenerator()
        end
    end
end

local configPropertySetter = function(config, propertyName)
    return function(value)
        config[propertyName] = value
    end
end

local logLevelSetter = function(config, propertyName)
    return function(level)
        config[propertyName] = Levels.parse(level)
    end
end

local syntaxSugar = function() end

local buildConfigUsingLoaderDsl = function(loaderFunction)
    local config = {}
    local dslEnv = {
        config = syntaxSugar,
        pattern = configPropertySetter(config, "pattern"),
        minLevel = logLevelSetter(config, "minLevel"),
        maxLevel = logLevelSetter(config, "maxLevel"),
        filter = configPropertySetter(config, "filter"),
        appenders = runAppenderGenerators,
        appender = function(module)
            return appenderCreator(config, module)
        end,
        console = appenderCreator(config, "console", "lua-industrial-logger.ConsoleAppender"),
        file = appenderCreator(config, "file", "lua-industrial-logger.FileAppender")
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
