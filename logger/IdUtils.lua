MAX_ID_LENGTH = 10

local generateNonUniqueId = function()
    local threadAddress = tostring({}):sub(10)

    local threadAddressLetters = threadAddress:gsub("%d", "")
    local threadAddressNumbers = threadAddress:gsub("[a-z]", "")

    local threadAddressNumber = tonumber(threadAddressNumbers)
    local maxNumberWidth = MAX_ID_LENGTH - threadAddressLetters:len()
    local maxRandomNumber = tonumber(string.rep("9", maxNumberWidth))

    math.randomseed(os.time() + threadAddressNumber)

    local randomNumber = math.random(maxRandomNumber)
    local idFormatString = string.format("%s%d%s", "%s%0", maxNumberWidth, "d")

    return string.format(idFormatString, threadAddressLetters, randomNumber)
end

return
{
    generateNonUniqueId = generateNonUniqueId
}
