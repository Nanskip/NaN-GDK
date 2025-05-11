Modules = {
    worldgen = "modules/worldgen.lua",
    loading_screen = "modules/loading_screen.lua",
}

Models = {
    soda_can = "models/soda_can.glb",
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