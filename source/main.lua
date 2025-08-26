_ON_START_CLIENT = function()
    _UI = require("uikit") -- _UI is uikit.lua

    loading_screen:init()
end

_ON_START = function()
    loading_screen:remove()
end
