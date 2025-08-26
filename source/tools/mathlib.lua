local mod = {}

mod.lerp = function(a, b, t)
    return a + (b - a) * t
end

return mod