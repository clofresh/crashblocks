local Sound = {}

local rng = nil

function Sound.load()
  rng = love.math.newRandomGenerator(1)
  Sound.beep = {}
  for i = 1, 1 do
    Sound.beep[i] = love.audio.newSource(string.format('assets/sounds/beep%s.wav', i))
  end
  Sound.disappear = love.audio.newSource('assets/sounds/disappear.wav')
  Sound.teleport = love.audio.newSource('assets/sounds/teleport.wav')
  Sound.move = love.audio.newSource('assets/sounds/move.wav')
end

function Sound.playBeep(i)
  local i = i or rng:random(1, #Sound.beep)
  Sound.beep[i]:play()
end


return Sound
