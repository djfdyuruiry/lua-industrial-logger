local ConsoleAppender = function(loggerConfig)
    return
    {
        append = function(logMessage)
            io.write(logMessage)
            io.write("\r\n")
        end
    }
end

return ConsoleAppender
