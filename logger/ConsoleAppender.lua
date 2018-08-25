local AnsiDecoratedStringBuilder = require "logger.AnsiDecoratedStringBuilder"
local StringUtils = require "logger.StringUtils"

local ConsoleAppender = function(name, appenderConfig)
    local config = appenderConfig or {}
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
            if config.colours then
                logMessage = AnsiDecoratedStringBuilder(logMessage)
                    .modifier(config.colours.modifier)
                    .foregroundColour(config.colours.foregroundColour)
                    .backgroundColour(config.colours.backgroundColour)
                    .build()
            end

            outputStream:write(logMessage)
            outputStream:write("\r\n")
        end
    }
end

return ConsoleAppender
