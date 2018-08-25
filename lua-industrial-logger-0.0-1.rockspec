package = "lua-industrial-logger"
version = "0.0-1"
source = {
    url = "git://github.com/djfdyuruiry/lua-industrual-strength-logging.git",
    tag = "master"
}
description = {
        summary = "A logging framework adding simple, powerful and reliable logs to any Lua application",
        detailed = [[
            See: https://github.com/djfdyuruiry/lua-industrual-strength-logging/blob/master/README.md

            Created by djfdyuruiry: https://github.com/djfdyuruiry
        ]],
        license = "MIT",
}
dependencies = {
    "lua >= 5.1"
}
build = {
    type = "builtin",
    modules = {
        ["lua-industrial-logger"] = "logger/*"
    },
    copy_directories = {}
}
