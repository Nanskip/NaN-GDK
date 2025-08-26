_ON_START_CLIENT = function()
    _UI = require("uikit") -- _UI is uikit.lua
    _DEBUG = _DIR.debug

    _DIR.loading_screen.loading_screen:init()
end

_ON_START = function()
    _DIR.loading_screen.loading_screen:intro()

    -- test music

    _DIR.test:init()
end
