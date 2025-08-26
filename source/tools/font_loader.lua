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

    for ch in group.text:gmatch(utf8.charpattern) do
        local frame = _UI:createFrame()
        frame.ch = ch

        group.frames[#group.frames + 1] = frame
    end

    group.update = function(_)
        _.currentOffsetX = 0

        for i = 1, #_.frames do
            local frame = _.frames[i]
            local data = _.fontData[frame.ch]

            local width = _.fontData.Size.Width
            local height = _.fontData.Size.Height

            frame.size = Number2(data.w, data.h)

            frame.pos = Number2(
                _.config.pos.X + _.currentOffsetX,
                _.config.pos.Y
            )
            frame.object.Image = { data = _.fontImage, alpha = true}
            frame.object.Tiling = Number2(data.w/width, data.h/height)
            frame.object.Offset = Number2(data.x/width, data.y/height)
            frame.Color = _.config.color

            _.currentOffsetX = _.currentOffsetX + data.w
        end
    end

    group.setText = function(_, text)
        if type(text) ~= "string" then
            _DEBUG.error("font_group:setText(text): text must be a string")

            return
        end

        _.text = text

        for i = 1, #_.frames do
            local frame = _.frames[i]
            frame:remove()
        end

        _.frames = {}
        _.currentOffsetX = 0

        for ch in group.text:gmatch(utf8.charpattern) do
            local frame = _UI:createFrame()
            frame.ch = ch
            _DEBUG.log(ch)

            _.frames[#_.frames + 1] = frame
        end

        _:update()
    end

    group:update()

    return group
end

return mod