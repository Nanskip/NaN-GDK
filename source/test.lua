local mod = {}

mod.init = function(self)
    print("yoooo!!!")

    local music = AudioSource()
    music:SetParent(Camera)
    music.Volume = 0.5
    music.Loop = true
    music.Sound = _DIR.music_pack.jazz2_mp3

    music:Play()
end

return mod