keyMappings = {
    ["a"] = "left",
    ["d"] = "right",
    ["s"] = "down",
    [" "] = "rotate",
}

function getInputs()
    local inputs = {}
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
