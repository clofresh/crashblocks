keyMappings = {
    ["a"] = "left",
    ["d"] = "right",
    ["s"] = "down",
    [" "] = "rotate",
}

gamepads = {
    -- ouya controller
    ["4f5559412047616d6520436f6e74726f"] = {
        {"a", "button", 6},
        {"b", "button", 7},
        {"x", "button", 9},
        {"y", "button", 10},
        {"leftstick", "button", 16},
        {"rightstick", "button", 17},
        {"leftshoulder", "button", 12},
        {"rightshoulder", "button", 13},
        {"dpup", "button", 1},
        {"dpdown", "button", 2},
        {"dpleft", "button", 3},
        {"dpright", "button", 4},
        {"leftx", "axis", 1},
        {"lefty", "axis", 2},
        {"rightx", "axis", 4},
        {"righty", "axis", 5},
        {"triggerleft", "axis", 3},
        {"triggerright", "axis", 6},
    },
    -- wired xbox 360 controller
    ["4d6963726f736f667420582d426f7820"] = {
        {"a", "button", 6},
        {"b", "button", 7},
        {"x", "button", 9},
        {"y", "button", 10},
        {"leftstick", "button", 16},
        {"rightstick", "button", 17},
        {"leftshoulder", "button", 12},
        {"rightshoulder", "button", 13},
        {"start", "button", 18},
        {"leftx", "axis", 1},
        {"lefty", "axis", 2},
        {"rightx", "axis", 4},
        {"righty", "axis", 5},
        {"triggerleft", "axis", 3},
        {"triggerright", "axis", 6},
    },
    -- bootleg snes usb controller
    ["32417865732031314b6579732047616d"] = {
        {"a", "button", 8},
        {"b", "button", 7},
        {"x", "button", 6},
        {"y", "button", 9},
        {"leftshoulder", "button", 10},
        {"rightshoulder", "button", 11},
        {"dpup", "button", 1},
        {"dpdown", "button", 2},
        {"dpleft", "button", 3},
        {"dpright", "button", 4},
        {"back", "button", 14},
        {"start", "button", 15},
        {"leftx", "axis", 1},
        {"lefty", "axis", 2},
    }
}

function initGamepads()
    local worked
    for guid, mappings in pairs(gamepads) do
        for i, mapping in pairs(mappings) do
            love.joystick.setGamepadMapping(guid, unpack(mapping))
        end
    end
end

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
