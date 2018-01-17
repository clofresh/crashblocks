keyMappings = {
    ["a"] = "left",
    ["d"] = "right",
    ["s"] = "down",
    ["space"] = "rotate",
}

touches = {}

function getInputs()
    local inputs = {touches = touches}
    getKeyboardInputs(inputs)
    return inputs
end

function getKeyboardInputs(inputs)
    for key, event in pairs(keyMappings) do
        if love.keyboard.isDown(key) then
            inputs[event] = true
        end
    end
    for id, touch in pairs(touches) do
        local swipe = {x = touch.endPos.x - touch.startPos.x,
                       y = touch.endPos.y - touch.startPos.y}
        local mag = math.sqrt(swipe.x * swipe.x + swipe.y * swipe.y)
        if mag > 3 then
            swipe.x = swipe.x / mag
            swipe.y = swipe.y / mag
            local angle = math.atan2(swipe.y, swipe.x)
            local dir = angle / math.pi
            if dir < -0.3 and dir > -0.7 then
                inputs.rotate = true
            elseif dir > 0.3 and dir < 0.7 then
                inputs.down = true
            elseif math.abs(dir) > 0.8 then
                inputs.left = true
            elseif math.abs(dir) < 0.2 then
                inputs.right = true
            end
        end
        break
    end
end

function love.touchpressed(id, x, y)
    touches[id] = {startPos = {x = x, y = y}, endPos = {x = x, y = y}}
end

function love.touchmoved(id, x, y, dx, dy, pressure)
    if touches[id] then
        touches[id].endPos.x = x
        touches[id].endPos.y = y
    end
end

function love.touchreleased(id, x, y)
    touches[id] = nil
end
