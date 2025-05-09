Modules = {
    worldgen = "modules/worldgen.lua",
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

Client.OnStart = function()
    worldgen.test()
end