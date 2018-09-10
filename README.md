# Lua Industrial Logger

A pure lua logging framework that follows the conventions of popular frameworks like `logback`, `log4net` and `log4j`

**Important: if you wish to rollover logs or compress old log files you will need certain utilities installed in your environment, see `rollingFile` in the `Config Reference` section below for more info**

### Quickstart

Install using [luarocks](https://github.com/luarocks/luarocks/wiki/Download)

`luarocks install lua-industrial-logger`

To use, import the module and create a new logger instance:

```lua
local LoggerFactory = require "lua-industrial-logger.LoggerFactory"

local logger = LoggerFactory.getLogger()
```

By default this will use the name of the lua file it was declared in as the logger name, but you can set a custom name:

```lua
local logger = LoggerFactory.getLogger("friendlyName")
```

Write log messages using the logger instance:

```lua
logger.info("Hello")
logger.error("Danger!")
logger.warn("Warning!")
logger.debug("Debug")
logger.trace("Trace")

-- supports formatting (following string.format rules)
local numLogMessages = 5

logger.info("I have printed out %d log messages", numLogMessages)
```

----

### Configuration

Logger settings can be managed in a configuration file. The path for this file defaults to `logger.lua.config` in the current working directory, see `Environment Variables` if you want to set a custom path.

If the file is not present, a default configuration is used:

- Console appender with TRACE level and log pattern of `%{iso8601}d [%t] %l %n - %m`

The configuration file follows a simple DSL syntax, below is an example:

```lua
-- define a log pattern and console appender
config {
    pattern "%{iso8601}d [%t] %l %n - %m",
    appenders {
        console "stdout"
    }
}
```

See `Config Reference` below for all the options you can specify.

----

### Environment Variables

This library uses environment variables to set global config values:

- `LUA_LOG_CFG_FILE`: Custom path to a logger config file 
- `LUA_LOG_DEBUG`: Set this to `true` to write verbose debug information to standard out

----

### Concepts

Concepts used in **Lua Industrial Logger** should be familiar to anyone who has worked with similar libraries: `Appenders`, `Patterns` and `Levels`

**Appenders** output log lines to various destinations:

- Console Appender (console)
    - Write output to standard streams
    - Supports coloured output
- File Appender (file)
    - Write output to a log file
- Rolling File Appender (rollingFile)
    - File Appender that rolls over to a new log file once a max size is reached, supports compression of old log files 

**Patterns** format the output of log lines, for example:

The pattern '`%d %l %n - %m` will output: `Mon Sep 10 20:53:48 2018 INFO  ./test.lua - Hello`

Supported pattern format specifiers:

- `%l` - Log level
- `%n` - Logger name
- `%t` - Thread ID
- `%d` - Date and time using current locale
    - equivalent to calling `os.date("%c")`
- `%{iso8601}d` - ISO8601 datetime
    - format is `YYYY-MM-DDTHH:mm:ssZ` e.x. `2018-12-30T21:49:16`
- `%m` - Log message

**Levels** define the context of a log message, supported levels:

- `TRACE`
- `DEBUG`
- `INFO`
- `WARN`
- `ERROR`
- `OFF` - This disables logging

----

### Config Reference

Below is the config DSL structure and available options:

*Note the log levels mentioned above are available as globals in the config DSL*

- `config`: root (syntax sugar)
    - `pattern`: log pattern to use
    - `minLevel`: minimum log level to log
    - `maxLevel`: maximum log level to log
    - `filter`: lua method that accepts a level as an argument and returns a boolean, return true to log message for the given level
    - `appenders`: list of appenders use
        - `console`: add a console appender 
            ```lua
                console "appenderName" {
                    -- config options
                }
            ```  
            - `stream`: standard stream to log to, default is 'stdout'
            - `colours`: configuration table fpr colours (optional)
                - `foreground`: foreground colour (optional)
                - `background`: background colour (optional)
                - `format`: format output (optional)
                - `forLevels`: map colours by log level (optional, overrides above properties)
                    ```lua
                    forLevels = {
                        ERROR = { foreground = "red" },
                        WARN  = { 
                            foreground = "bright yellow",
                            background = "black"
                        }
                    }
                    ```
        - `file`: add a file appender 
            ```lua
                file "appenderName" {
                    -- config options
                }
            ```  
            - `logFilePath`: path to the log file
            - `createMissingDirectories`: boolean, create missing directories when creating the log file, defaults to false (optional)
        - `rollingFile`: add a rolling file appender (*Note: On Windows, you will need Windows 7 or higher to use this*)
            ```lua
                rollingFile "appenderName" {
                    -- config options
                    rollover = {
                        -- rollover options
                    }
                }
            ```  
            - `logFilePath`: path to the log file
            - `createMissingDirectories`: boolean, create missing directories when creating the log file, defaults to false (optional)
            - `rollover`: configuration table for log rollover
                - `maxFileSizeInKb`: the maximum size of the log file before rolling over
                - `maxBackupFiles`: the maximum number of log backups to keep
                - `backupFileFormat`: backup log files in this format ('copy', 'zip' or 'tar')
                    - *On Windows: supported formats are 'copy' and 'zip' (note: zip format requires powershell v5 or newer to be installed)*
                    - *On Unix: supported formats are 'copy', 'tar' and 'zip' (note: tar and zip formats require the tar and zip utils to be available in the path)*
        - `appender`: add a custom appender
            ```lua
                appender("some.lua.Appender") "appenderName" {
                    -- 'some.lua.Appender' config options, if any
                }
            ```

**Common Appender Config**

All appenders can have any of the following optional config keys:

- `pattern`: override the log pattern for the appender
- `level`: log only messages with this log level
- `minLevel`: minimum log level to log
- `maxLevel`: maximum log level to log
- `filter`: lua method that accepts a level as an argument and returns a boolean, return true to accept the given level

Example:

```lua
    console "appenderName" {
        pattern = "%{iso8601}d %l %n - %m",
        level = ERROR,
    }
```

**Available Colours**:

- black
- red
- green
- yellow
- blue
- magenta
- cyan
- white 

*Prefix colour names with "bright" followed by a space for a lighter colour*

**Available formats**:

- bold
- faint
- italic
- underline
- crossthrough
  
----

### Customisation

This library supports custom appenders and configuration loaders. For example, you could write log lines to a database or load configuration from a web service.

**Custom Appender**

To implement a custom appender, create a Lua class which has:

- A constructor that accepts two parameters, the name of the logger and the appender config
- A method named `append` - accepts the message log level and the formatted log message
- A public field named `config` - the config for this appender

Example:

```lua
-- my/package/CustomAppender.lua
local CustomAppender = function(name, appenderConfig)
    local config = appenderConfig or {}

    local append = function(level, logMessage)
        -- do something with logMessage
    end
    
    return
    {
        append = append,
        config = config
    }
end

return CustomAppender
```

This appender can then be used in the config file:

```lua
config {
    appenders {
        appender("my.package.CustomAppender") "myName" {
            -- This is the appenderConfig passed to the constructor, put 
            -- any config you want to pass to your custom appender here.
        }
    }
}
```

**Custom Configuration Loader**

Coming Soon!
