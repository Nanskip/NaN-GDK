-- Debug module to store logs

local debug = {}

function debug.log(text)
    if _debug then
        print("Log: " .. text)
    end
end

debug._LOGS = {}

function debug.getLogs()
    local logs = ""

    for _, log in ipairs(debug._LOGS) do
        logs = logs .. log .. "\n"
    end

    Dev:CopyToClipboard(logs)
end

return debug