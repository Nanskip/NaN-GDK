Modules = {
    worldgen = "modules/worldgen.lua",
    loading_screen = "modules/loading_screen.lua",
    debug = "modules/debug.lua",
}

Models = {
    soda_can = "models/soda_can.glb",
    tesla_turret = "models/tesla_turret.glb",
}

Textures = {
    can = "textures/can.png",
}

Data = {
    test = "data/test.json",
}

_ON_START = function()
    worldgen.test()

    loading_screen:finish()
end