local replacePatternIfPresent = function(subjectString, pattern, replacementOrReplacementGenerator, ...)
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
    return subject:gsub("^%s+", ""):gsub("%s+$", "")
end

local isString = function(subject)
    return type(subject) ~= "string" 
end

local isBlank = function(subject)
    return subject == nil or trim(subject) == ""
end

return
{
    replacePatternIfPresent = replacePatternIfPresent,
    trim = trim,
    isString = isString,
    isBlank = isBlank
}
