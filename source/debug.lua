local mod = {}

mod.logs = {}

mod.error = function(msg)
    mod._print("[ERROR] "..tostring(msg))
end

mod.log = function(msg)
    mod._print("[LOG] "..tostring(msg))
end

mod._print = function(msg)
    local line = tostring(msg)

    local last = mod.logs[#mod.logs]
    if last and last.text == line then
        last.count = last.count + 1
    else
        last = { text = line, count = 1 }
        mod.logs[#mod.logs + 1] = last
        print(line)
    end
end

mod.copy = function()
    local t = ""

    for i = 1, #mod.logs do
        local entry = mod.logs[i]
        if entry.count > 1 then
            t = t..entry.text.." ["..entry.count.."x]\n"
        else
            t = t..entry.text.."\n"
        end
    end

    Dev:CopyToClipboard(t)
end


return mod