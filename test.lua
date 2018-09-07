#! /usr/bin/env lua
local LoggerFactory = require "lua-industrial-logger.LoggerFactory"

function main()
    local logger = LoggerFactory.getLogger()

    logger.info("Hello")
    logger.ERROR("Danger!")
    logger.warn("Warning!")
    logger.debug("Debug!")
    logger.trace("Trace!")
end

main()
