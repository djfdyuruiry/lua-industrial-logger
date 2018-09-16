#! /usr/bin/env lua
local LoggerFactory = require "lil.LoggerFactory"

function main()
    local logger = LoggerFactory.getLogger()

    logger.info("Hello")
    logger.ERROR("Danger!")
    logger.warn("Warning!")
    logger.debug("Debug!")
    logger.trace("Trace!")
end

main()
