local DebugLogger = require "lua-industrial-logger.DebugLogger"

local replacePatternIfPresent = function(subjectString, pattern, replacementOrReplacementGenerator, ...)
    DebugLogger.log("replacing string if present with subjectString = '%s' and pattern = '%s' and replacementOrReplacementGenerator = '%s'", subjectString, pattern, replacementOrReplacementGenerator)

    if not string.find(subjectString, pattern, 1, true) then
        return subjectString
    end

    local replacement = replacementOrReplacementGenerator

    if type(replacementOrReplacementGenerator) == "function" then
        replacement = replacementOrReplacementGenerator(...)
    end

    return subjectString:gsub(
        string.format("%%%s", pattern),
        replacement
    )
end

local trim = function(subject)
    DebugLogger.log("trimming with subject = '%s'", subject)

    return (subject:gsub("^%s+", ""):gsub("%s+$", ""))
end

local isString = function(subject)
    DebugLogger.log("checking is string with subject = '%s'", subject)

    return type(subject) ~= "string" 
end

local isBlank = function(subject)
    DebugLogger.log("checking is blank with subject = '%s'", subject)

    return subject == nil or trim(subject) == ""
end

local explodeString = function(subject, seperator)
    DebugLogger.log("exploding string with subject = '%s' and seperator = '%s'", subject, seperator)

    local strings = {}

    for str in string.gmatch(subject, seperator) do
        table.insert(strings, trim(str))
    end

    return strings
end

local concat = function(...)
    DebugLogger.log("concating strings")

    local result = ""    

    for _, str in ipairs(...) do
        result = ("%s%s"):format(result, str)
    end

    return result
end

return
{
    replacePatternIfPresent = replacePatternIfPresent,
    trim = trim,
    isString = isString,
    isBlank = isBlank,
    explodeString = explodeString,
    concat = concat
}
