local loading_screen = {}

loading_screen.ui = require("uikit")

loading_screen.start = function(self)
    local ui = self.ui

    self.background = ui:frame({color = Color(0, 0, 0, 0)})
    self.background.Width = Screen.Width
    self.background.Height = Screen.Height
end

loading_screen.finish = function(self)
    self.background:remove()
    self.background = nil
end

loading_screen:start()

return loading_screen