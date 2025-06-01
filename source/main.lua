Modules = {
    worldgen = "modules/worldgen.lua",
    loading_screen = "modules/loading_screen.lua",
    debug = "modules/debug.lua",
    mathlib = "modules/mathlib.lua",
}

Models = {

}

Textures = {
    intro_logo = "textures/intro_logo.png",
}

Sounds = {
    loading_completed = "sounds/loading_completed.mp3",
    intro = "sounds/intro.mp3",
}

Data = {

}

Other = {
    vcr_font = "other/vcr_font.ttf",
}

_ON_START = function()
    loading_screen:intro()
end

_ON_START_CLIENT = function()
    _UIKIT = require("uikit")
    _GAME_NAME = "GAME NAME"

    loading_screen:start()
end