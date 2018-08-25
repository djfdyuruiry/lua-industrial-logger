local AnsiDecoratedStringBuilder = require "lua-industrial-logger.AnsiDecoratedStringBuilder"
local StringUtils = require "lua-industrial-logger.StringUtils"

local ConsoleAppender = function(name, appenderConfig)
    local config = appenderConfig or {}
    local colourConfig = config.colours
    local outputStream

    local loadConfig = function()
        local outputStreamName = not StringUtils.isBlank(config.stream) and config.stream or "stdout"

        outputStream = io[outputStreamName]

        if not outputStream then
            error(
                string.format("Unable to set stream for ConsoleAppender '%s': '%s' is not a standard output stream",
                    name,
                    outputStreamName
                )
            )
        end
    end

    loadConfig()

    return
    {
        append = function(logMessage)
            if colourConfig then
                logMessage = AnsiDecoratedStringBuilder(logMessage)
                    .modifier(colourConfig.format)
                    .foregroundColour(colourConfig.foreground)
                    .backgroundColour(colourConfig.background)
                    .build()
            end

            outputStream:write(logMessage)
            outputStream:write("\r\n")
        end
    }
end

return ConsoleAppender
