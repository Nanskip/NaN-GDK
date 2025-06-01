local mathlib = {}

function mathlib.lerp(a, b, t)
    return a + (b - a) * t
end

return mathlib