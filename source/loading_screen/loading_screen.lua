local mod = {}

mod.init = function(self)
    if self ~= mod then
        _DEBUG.error("loading_screen.init: singleton error.")

        return
    end

    local config = {
        title = "Game Name",
        subtitle = "Powered by NaN-GDK!",
        status = "Downloading: ",
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
    self.title = _UI:createText()
    self.subtitle = _UI:createText()
    self.status = _UI:createText()
    self.progress_background = _UI:createFrame()
    self.progress = _UI:createFrame()

    self.initialized = true
    self:update()
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
    self.title.FontSize = 100
    self.title.pos = Number2(cx - self.title.Width / 2, cy - self.title.Height / 2 + 200)

    -- update subtitle
    self.subtitle.Text = config.subtitle
    self.subtitle.Color = config.subtitle_color
    self.subtitle.FontSize = 70
    self.subtitle.pos = Number2(cx - self.subtitle.Width / 2, cy - self.subtitle.Height / 2 + 100)

    -- update status
    self.status.Text = config.status
    self.status.Color = config.status_color
    self.status.FontSize = 40
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
    self.progress.Width = self.progress_background.Width * self.percentage
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

    self.initialized = false

    self.background:remove()
    self.title:remove()
    self.subtitle:remove()
    self.status:remove()
    self.progress_background:remove()
    self.progress:remove()
end

return mod