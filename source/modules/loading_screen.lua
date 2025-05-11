local loading = {}

loading.ui = require("uikit")

loading.start = function(self)
    local ui = self.ui

    self.background = ui:frame({color = Color(0, 0, 0, 0)})
end

loading.finish = function(self)
    self.background:remove()
end

return loading