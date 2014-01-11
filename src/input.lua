keyMappings = {
    ["a"] = "left",
    ["d"] = "right",
    ["s"] = "down",
    [" "] = "rotate",
}

function getInputs()
    local inputs = {}
    getControllerInputs(inputs)
    getKeyboardInputs(inputs)
    return inputs
end

function getKeyboardInputs(inputs)
    for key, event in pairs(keyMappings) do
        if love.keyboard.isDown(key) then
            inputs[event] = true
        end
    end
end

function getControllerInputs(inputs)
    local joysticks = love.joystick.getJoysticks()
    for i, joystick in ipairs(joysticks) do
        if joystick:isGamepad() then
            local lxAxis = joystick:getGamepadAxis("leftx")
            local lyAxis = joystick:getGamepadAxis("lefty")
            if lxAxis >= 0.3 then
                inputs.right = true
            elseif lxAxis <= -0.3 then
                inputs.left = true
            end
            if lyAxis >= 0.3 then
                inputs.down = true
            end
            if joystick:isGamepadDown("a") then
                inputs.rotate = true
            end
        end
    end
end
