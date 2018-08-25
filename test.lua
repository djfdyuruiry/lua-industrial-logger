#! /usr/bin/env lua
local LoggerFactory = require "lua-industrial-logger.LoggerFactory"

local logger = LoggerFactory.getLogger("test.lua")

logger.info("Hello")
logger.ERROR("Danger!")
logger.warn("Warning!")
logger.debug("Debug!")
logger.trace("Trace!")
