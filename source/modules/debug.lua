-- Debug module to store logs

local debug = {}

function debug.log(text)
    if _debug then
        print("Log: " .. text)
    end
    debug._LOGS[#debug._LOGS+1] = text
    debug:updateConsole()
end

debug._LOGS = {}

function debug.getLogs()
    local logs = ""

    for _, log in ipairs(debug._LOGS) do
        logs = logs .. log .. "\n"
    end

    Dev:CopyToClipboard(logs)
end

function debug.openConsole(self)
    local cfg = {
        title = "Console",
        title_size = 14,
        width = 800,
        height = 450,
        topbar_height = 20,
        topbar_color = Color(18, 23, 20),
        topbar_text_color = Color(225, 225, 225),
        background_color = Color(27, 33, 29),
        border_color = Color(0, 0, 0),
        border_width = 2,
        pos = {0, 0},
        topbar_buttons = {
            {
                text = "X",
                func = "close",
                size = 14,
                color = Color(18, 23, 21),
                textcolor = Color(225, 225, 225)
            }
        }
    }
    local console = _UI.createWindow(cfg)

    local textcfg = {
            pos = {5, 5},
            color = Color(255, 255, 255),
            fontsize = 14,
            text = "CONSOLE OUTPUT",
        }
    console.text = console:createText(textcfg)

    self.console = console
    self:updateConsole()
end

debug.updateConsole = function(self)
    if self.console ~= nil then
        local text = ""
        for _, log in ipairs(self._LOGS) do
            text = text .. log
            if _ ~= #self._LOGS then
                text = text .. "\n"
            end
        end
        self.console.text.config.text = text

        self.console.text:update()
    end
end

return debug