require('src/grid')
require('src/block')
require('src/states')
require('src/effects')

mouseGridPos = {0, 0}

function love.load()
    math.randomseed(1)
    for i, color in pairs(colors) do
        crashBlocks[color] = {}
    end
    nextPair = newPair()
    state = tryNew
    blurHorizontal = love.graphics.newCanvas()
    blurVertical = love.graphics.newCanvas()
    effect:send('imageSize', {love.graphics.getWidth(), love.graphics.getHeight()})
    effect:send('radius', 3)
end

function love.update(dt)
    if arg[#arg] == "-debug" then require("mobdebug").start() end

    local x, y = love.mouse.getPosition()
    mouseGridPos = {math.floor(x / gridInfo.tileWidth),
                    math.floor(y / gridInfo.tileHeight)}
    if mouseGridPos[1] < 1 or mouseGridPos[1] >= gridInfo.w then
        mouseGridPos[1] = "n/a"
    end
    if mouseGridPos[2] < 1 or mouseGridPos[2] >= gridInfo.h then
        mouseGridPos[2] = "n/a"
    end
    state(dt)
end

function love.draw()
    blurHorizontal:clear()
    blurVertical:clear()
    love.graphics.setCanvas(blurHorizontal)

    if currentPair then
        local firstX, firstY, secondX, secondY = getGridCoords(currentPair)
        drawBlock(firstX, firstY, currentPair.first)
        drawBlock(secondX, secondY, currentPair.second)
    end

    for x, ys in pairs(grid) do
        for y, blockInfo in pairs(ys) do
            drawBlock(x, y, blockInfo)
        end
    end
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.print(string.format("(%s, %s)", mouseGridPos[1], mouseGridPos[2]), 0, 0)

    love.graphics.setPixelEffect(effect)

    effect:send('direction', {1,0})
    love.graphics.setCanvas(blurVertical)
    love.graphics.draw(blurHorizontal, 0,0)

    effect:send('direction', {0,1})
    love.graphics.setCanvas()
    love.graphics.draw(blurVertical, 0,0)
    love.graphics.setPixelEffect()

end
