local advanced_ui = {}
advanced_ui.version = "0.1"

advanced_ui.init = function(self)
    -- logs to check if everything is ok
    debug.log("-- ADVANCED UI --")
    debug.log("Version: " .. self.version)
    debug.log("Made for NaN-GDK.")
    debug.log("Advanced UI Module initialized.")
end

advanced_ui.createWindow = function(config)
    -- default config
    local defaultConfig = {
        title = "Window",
        title_size = 14,
        width = 300,
        height = 200,
        topbar_height = 20,
        topbar_color = Color(92, 101, 105),
        topbar_text_color = Color(218, 224, 227),
        background_color = Color(200, 216, 224),
        border_color = Color(31, 34, 36),
        border_width = 1,
        pos = {0, 0},
        topbar_buttons = {
            {
                text = "X",
                func = "close",
                size = 14,
                color = Color(237, 66, 24),
                textcolor = Color(255, 255, 255)
            }
        }
    }

    -- config merging
    local cfg = {}
    for k, v in pairs(defaultConfig) do
        if config[k] ~= nil then
            cfg[k] = config[k]
        else
            cfg[k] = v
        end
    end

    -- creating window
    local window = _UIKIT:createFrame()
    window.mask = _UIKIT:createFrame()
    window.mask:_setIsMask(true)
    window.left_border = _UIKIT:createFrame()
    window.right_border = _UIKIT:createFrame()
    window.bottom_border = _UIKIT:createFrame()
    window.top_border = _UIKIT:createFrame()

    -- topbar + events
    window.topbar = _UIKIT:createFrame()
    window.title = _UIKIT:createText(cfg.title)
    window.topbar.onPress = function(self, _quad, _idk, pointerEvent)
        debug.log("Pressed top border of window " .. window.config.title)
        debug.log("Position: [X:" .. pointerEvent.X .. ", Y:" .. pointerEvent.Y .. "]")
        self.latest_pointer_position = {X = pointerEvent.X, Y = pointerEvent.Y}
    end
    window.topbar.onRelease = function(self)
        debug.log("Released top border of window " .. window.config.title)
        self.latest_pointer_position = nil
    end
    window.topbar.onDrag = function(self, pointerEvent)
        if self.latest_pointer_position.X ~= nil and self.latest_pointer_position.Y ~= nil then
            local pos_diff = {
                X = (pointerEvent.X - self.latest_pointer_position.X) * window.screen_mult[1],
                Y = (pointerEvent.Y - self.latest_pointer_position.Y) * window.screen_mult[2],
            }
            local final_pos = {
                window.pos.X + pos_diff.X,
                window.pos.Y + pos_diff.Y,
            }
            self.latest_pointer_position = {X = pointerEvent.X, Y = pointerEvent.Y}
            window:setPos(final_pos)
        end
    end

    window.onPress = function(self, _quad, _idk, pointerEvent)
        debug.log("Window [" .. window.config.title .. "] focused.")
    end

    -- creating topbar buttons
    window.topbar_buttons = {}
    for i, button in ipairs(cfg.topbar_buttons) do
        local btn = _UIKIT:createFrame()
        btn.btn_text = _UIKIT:createText(button.text)
        btn.onRelease = function(self)
            debug.log("Button " .. button.text .. " pressed")
            if button.func == "close" then
                window:close(true)
            end
        end
        table.insert(window.topbar_buttons, btn)
    end

    -- SAVE CONFIG
    window.config = cfg

    -- -- -- FUNCTIONS -- -- --

    window.updateConfig = function(self, config)
        -- merging old config with new one
        local mergedConfig = {}
        for k, v in pairs(self.config) do
            mergedConfig[k] = v
        end

        -- merging new config with old one
        for k, v in pairs(config) do
            mergedConfig[k] = v
        end

        -- updating config
        self.config = mergedConfig

        -- updating window
        self:update()
    end

    window.setPos = function(self, pos)
        self.config.pos = pos
        self:update()
    end

    window.setSize = function(self, size)
        self.config.width = size[1]
        self.config.height = size[2]
        self:update()
    end

    window.update = function(self)
        -- updating window
        self.Color = self.config.background_color
        self.Size = {self.config.width, self.config.height}
        self.pos = self.config.pos

        -- updating mask
        self.mask.Color = Color(255, 255, 255, 0)
        self.mask.Size = {self.config.width, self.config.height}
        self.mask.pos = self.config.pos

        -- updating topbar
        self.topbar.Color = self.config.topbar_color
        self.topbar.Size = {self.config.width, self.config.topbar_height}
        self.topbar.pos = {self.pos.X, self.pos.Y + self.config.height - self.topbar.Height}

        -- updating title
        self.title.Color = self.config.topbar_text_color
        self.title.object.FontSize = self.config.title_size
        self.title.pos = {
            self.topbar.pos.X + (self.config.topbar_height-self.config.title_size)/2,
            self.topbar.pos.Y + (self.config.topbar_height-self.config.title_size)/2
        }

        -- updating left border
        self.left_border.Color = self.config.border_color
        self.left_border.Size = {self.config.border_width, self.config.height}
        self.left_border.pos = {self.pos.X-self.config.border_width, self.pos.Y}

        -- updating right border
        self.right_border.Color = self.config.border_color
        self.right_border.Size = {self.config.border_width, self.config.height}
        self.right_border.pos = {self.pos.X+self.config.width, self.pos.Y}

        -- updating bottom border
        self.bottom_border.Color = self.config.border_color
        self.bottom_border.Size = {self.config.width + (self.config.border_width * 2), self.config.border_width}
        self.bottom_border.pos = {self.pos.X- self.config.border_width, self.pos.Y-self.config.border_width}

        -- updating top border
        self.top_border.Color = self.config.border_color
        self.top_border.Size = {self.config.width + (self.config.border_width * 2), self.config.border_width}
        self.top_border.pos = {self.pos.X - self.config.border_width, self.pos.Y + self.config.height}

        -- updating topbar buttons
        for i, btn in ipairs(self.topbar_buttons) do
            btn.btn_text.object.FontSize = self.config.topbar_buttons[i].size
            btn.Height = btn.btn_text.Height + self.config.border_width * 2
            btn.Width = math.max(
                btn.btn_text.Height + self.config.border_width * 2,
                btn.btn_text.Width + self.config.border_width * 2
            )
            btn.Color = self.config.topbar_buttons[i].color
            btn.pos = {
                self.topbar.pos.X + self.config.width - ((btn.Width + self.config.border_width)*i),
                self.topbar.pos.Y + (self.config.topbar_height-btn.Height)/2
            }
            btn.btn_text.pos = {
                btn.pos.X + (btn.Width - btn.btn_text.Width)/2,
                btn.pos.Y + (btn.Height - btn.btn_text.Height)/2
            }
            btn.btn_text.Color = self.config.topbar_buttons[i].textcolor
        end

        self.screen_mult = {Screen.Width, Screen.Height}
    end

    window.destroy = function(self)
        debug.log("Destroying window " .. self.config.title)

        self.left_border:remove()
        self.right_border:remove()
        self.bottom_border:remove()
        self.top_border:remove()
        self.topbar:remove()
        self.title:remove()
        for _, btn in ipairs(self.topbar_buttons) do
            btn.btn_text:remove()
            btn:remove()
        end
        for _, val in ipairs(self._CONTENT) do
            val:remove()
        end
        self.mask:remove()
        self:remove()
    end

    window.close = function(self, destroy)
        debug.log("Closing window " .. self.config.title)

        if not destroy then
            self.pos = {-1000, -1000}
            self:update()
        else
            self:destroy()
        end
    end

    window:update()
    window._CONTENT = {}

    window.createFrame = function(_, config)
        local defaultConfig = {
            pos = {0, 0},
            size = {0, 0},
            color = Color(255, 255, 255),
            id = #window._CONTENT+1,
        }

        local cfg = {}
        for k, v in pairs(defaultConfig) do
            if config[k] ~= nil then
                cfg[k] = config[k]
            else
                cfg[k] = v
            end
        end

        -- creating frame
        local frame = _UIKIT:createFrame()
        frame.config = cfg

        function frame.update(self)
            frame.pos = cfg.pos
            frame.Size = cfg.size
            frame.Color = cfg.color
            frame.id = cfg.id
        end
        frame:setParent(window.mask)
        table.insert(window._CONTENT, frame)

        frame:update()

        return frame
    end

    window.createText = function(_, config)
        local defaultConfig = {
            pos = {0, 0},
            color = Color(255, 255, 255),
            fontsize = 14,
            text = "Sample",
            id = #window._CONTENT+1,
        }

        local cfg = {}
        for k, v in pairs(defaultConfig) do
            if config[k] ~= nil then
                cfg[k] = config[k]
            else
                cfg[k] = v
            end
        end

        -- creating text
        local text = _UIKIT:createText("")
        text.config = cfg

        function text.update(self)
            self.pos = self.config.pos
            self.Color = self.config.color
            self.Text = self.config.text
            self.object.FontSize = self.config.fontsize
            self.id = self.config.id
        end
        text:setParent(window.mask)
        table.insert(window._CONTENT, text)

        text:update()

        return text
    end

    return window
end