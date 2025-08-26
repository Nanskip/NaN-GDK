local mod = {}

mod.init = function(self)
    if self ~= mod then
        _DEBUG.error("loading_screen.init: singleton error.")

        return
    end

    _DEBUG.log("loading_screen.init()")

    local config = {
        title = "Game Name",
        subtitle = "Powered by NaN-GDK!",
        status = "Downloading... [0%]",
        background_color = Color(0, 0, 0),
        title_color = Color(255, 255, 255),
        subtitle_color = Color(255, 255, 255),
        status_color = Color(255, 255, 255),
        progress_color = Color(71, 255, 93),
        progress_background_color = Color(100, 100, 100),
    }

    self.config = config
    self.percentage = 0

    self.background = _UI:createFrame()
    self.title = _UI:createText("")
    self.subtitle = _UI:createText("")
    self.status = _UI:createText("")
    self.progress_background = _UI:createFrame()
    self.progress = _UI:createFrame()

    self.initialized = true
    self:update()
    
    self.tick = Object()
    self.tick.Tick = function(s, dt)
        if self.initialized then
            if self.running_intro then
                self.config.title_color.A = math.max(self.config.title_color.A - 10, 0)
                self.config.subtitle_color.A = math.max(self.config.subtitle_color.A - 10, 0)
                self.config.status_color.A = math.max(self.config.status_color.A - 10, 0)
                self.config.progress_color.A = math.max(self.config.progress_color.A - 10, 0)
                self.config.progress_background_color.A = math.max(self.config.progress_background_color.A - 10, 0)

                self.intro_timer = self.intro_timer + dt
                if self.intro_timer > 0.5 then
                    self.config.background_color.A = math.max(self.config.background_color.A - 20, 0)
                end
            end
            if self.percentage ~= 0 then
                self:update()
            end
        end
    end
end

mod.update = function(self)
    if self ~= mod then
        _DEBUG.error("loading_screen.update: singleton error.")

        return
    end

    if not self.initialized then
        _DEBUG.error("loading_screen.update: not initialized")

        return
    end

    _DEBUG.log("loading_screen.update()")

    local cx = Screen.Width / 2
    local cy = Screen.Height / 2

    local config = self.config

    -- update background
    self.background.Color = config.background_color
    self.background.Width = Screen.Width
    self.background.Height = Screen.Height

    -- update title
    self.title.Text = config.title
    self.title.Color = config.title_color
    self.title.object.DrawMode = {
        outline = { weight=0.05, color=config.title_color }
    }
    self.title.object.FontSize = 70
    self.title.pos = Number2(cx - self.title.Width / 2, cy - self.title.Height / 2 + 150)

    -- update subtitle
    self.subtitle.Text = config.subtitle
    self.subtitle.Color = config.subtitle_color
    self.subtitle.object.FontSize = 50
    self.subtitle.pos = Number2(cx - self.subtitle.Width / 2, cy - self.subtitle.Height / 2 + 75)

    -- update status
    config.status = "Downloading... [" .. math.floor(self.percentage * 100) .. "%]"
    self.status.Text = config.status
    self.status.Color = config.status_color
    self.status.object.FontSize = 40
    self.status.pos = Number2(cx - self.status.Width / 2, cy - self.status.Height / 2)

    -- update progress bar
    self.progress_background.Color = config.progress_background_color
    self.progress_background.Width = 550
    self.progress_background.Height = 20
    self.progress_background.pos = Number2(
        cx - self.progress_background.Width / 2,
        cy - self.progress_background.Height / 2 - 60
    )

    self.progress.Color = config.progress_color
    self.progress.Width = _DIR.tools.mathlib.lerp(
        self.progress.Width,
        self.progress_background.Width * self.percentage,
        0.1
    )
    self.progress.Height = self.progress_background.Height
    self.progress.pos = Number2(
        cx - self.progress_background.Width / 2,
        cy - self.progress_background.Height / 2 - 60
    )
end

mod.remove = function(self)
    if self ~= mod then
        _DEBUG.error("loading_screen.remove: singleton error.")

        return
    end

    if not self.initialized then
        _DEBUG.error("loading_screen.remove: not initialized")

        return
    end

    _DEBUG.log("loading_screen.remove()")

    self.initialized = false

    self.tick:Destroy()
    self.tick = nil

    self.background:remove()
    self.title:remove()
    self.subtitle:remove()
    self.status:remove()
    self.progress_background:remove()
    self.progress:remove()
end

mod.intro = function(self)
    self.percentage = 1
    self.running_intro = true
    self.intro_timer = 0

    Timer(1, false, function()
        self:remove()
    end)
end

return mod