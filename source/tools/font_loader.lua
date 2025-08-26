-- custom font loader using atlas.json and atlas.png

local mod = {}

-- currently only for ui texts

mod.createText = function(self, text, fontData, fontImage, config)
    local defaultConfig = {
        color = Color(0, 0, 0, 255),
        size = 20,
        pos = Number2(0, 0),
    }

    local config = config or defaultConfig

    local group = {} -- group for ui frames

    group.config = config
    group.text = text
    group.fontData = JSON:Decode(fontData)
    group.fontImage = fontImage
    group.frames = {}

    -- create frames

    group.currentOffsetX = 0
    for ch in group.text:gmatch('.') do
        print(ch)
        local frame = _UI:createFrame()
        local data = group.fontData[ch]

        frame.size = Number2(data.w, data.h)
        frame.pos = Number2(
            group.config.pos.X + group.currentOffsetX,
            group.config.pos.Y
        )
        group.currentOffsetX = group.currentOffsetX + data.w
        frame.object.Image = { data = group.fontImage, alpha = true}
        frame.object.Tiling = Number2(data.w/546, data.h/780)
        frame.object.Offset = Number2(data.x/546, data.y/780)
        frame.Color = group.config.color
    end

    group.update = function(_)
        for key, value in _.frames do
            value.frame.Color = _.config.color
        end
    end
end

return mod