local main = {}

main.debug = false
main.download_finished = false

function main.download(self)
    local modules = {
        test = "lib/modules/test.lua"
    }

    for key, value in pairs(modules) do
        HTTP:Get("https://raw.githubusercontent.com/Nanskip/NaN-GDK/refs/heads/main/" .. value, function(res)
            if res.StatusCode ~= 200 then
                print("Error getting module: " .. key .. " - " .. res.StatusCode)
            end

            self[key] = loadstring(res.Body)()
            if self.debug then
                print("Module loaded: " .. key)
            end
        end)
    end
end

return main