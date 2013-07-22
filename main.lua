grid = nil
gridInfo = nil
colors = nil
colorVals = nil
types = nil
nextDir = nil
state = nil
startX = nil
startY = nil
startDir = nil
crashBlocks = nil
mouseGridPos = nil

function randomBlock()
    local randType = math.random(1, 100)
    local type
    if randType > 70 then
        type = 'crash'
    else
        type = 'normal'
    end
    return {
        color = colors[math.random(1, #colors)],
        type = type
    }
end

function newPair()
    return {
        first = randomBlock(),
        second = randomBlock(),
        dir = nil,
        x = nil,
        y = nil,
    }
end

function colorVal(name)
    return unpack(colorVals[name])
end

function canMove(newX, newY, newDir)
    local firstX, firstY, secondX, secondY = getGridCoords({
        x = newX, y = newY, dir = newDir
    })

    return math.min(firstX, secondX) >= 1
       and math.max(firstX, secondX) < gridInfo.w
       and math.min(firstY, secondY) >= 1
       and math.max(firstY, secondY) < gridInfo.h
       and not gridGet(grid, firstX, firstY)
       and not gridGet(grid, secondX, secondY)
end

function tryNew(dt)
    if canMove(startX, startY, startDir) then
        currentPair = nextPair
        currentPair.x = startX
        currentPair.y = startY
        currentPair.dir = startDir
        nextPair = newPair()
        state = inControl
    else
        print("Game over")
        love.event.quit()
    end
end

function inControl(dt)
    local newX, newY, newDir, down
    if love.keyboard.isDown("a") then
        newX = currentPair.x - 1
        newY = currentPair.y
        newDir = currentPair.dir
    elseif love.keyboard.isDown("d") then
        newX = currentPair.x + 1
        newY = currentPair.y
        newDir = currentPair.dir
    elseif love.keyboard.isDown("s") then
        newX = currentPair.x
        newY = currentPair.y + 1
        newDir = currentPair.dir
        down = true
    elseif love.keyboard.isDown(" ") then
        newX = currentPair.x
        newY = currentPair.y
        newDir = nextDir[currentPair.dir]
    end

    if newX and canMove(newX, newY, newDir) then
        currentPair.x = newX
        currentPair.y = newY
        currentPair.dir = newDir
        local delayAmount
        if down then
            delayAmount = 0.01
        else
            delayAmount = 0.1
        end
        state = delay(delayAmount, inControl)
    elseif down then
        local firstX, firstY, secondX, secondY = getGridCoords(currentPair)
        gridSet(grid, firstX, firstY, currentPair.first)
        gridSet(grid, secondX, secondY, currentPair.second)

        if currentPair.first.type == 'crash' then
            table.insert(crashBlocks[currentPair.first.color],
                         {firstX, firstY, currentPair.first})
        end
        if currentPair.second.type == 'crash' then
            table.insert(crashBlocks[currentPair.second.color],
                         {secondX, secondY, currentPair.second})
        end
        currentPair = nil

        state = function(dt)
            applyGravity(clearBlocks, dt)
        end
    end
end

function delay(delayTimeLimit, nextState)
    local delayTime = 0
    return function(dt)
        delayTime = delayTime + dt
        if delayTime > delayTimeLimit then
            state = nextState
        end
    end
end

function applyGravity(nextState, dt)
    local changed = false
    for x, col in pairs(grid) do
        local prevBlock, currentBlock
        for y = gridInfo.h - 2, 1, -1 do
            prevBlock = col[y + 1]
            currentBlock = col[y]
            if currentBlock and not prevBlock then
                local newY = y + 1
                col[newY] = currentBlock
                col[y] = nil
                changed = true
                if currentBlock.type == 'crash' then
                    for i, colorCrashBlock in pairs(crashBlocks[currentBlock.color]) do
                        if colorCrashBlock[1] == x and colorCrashBlock[2] == y then
                            colorCrashBlock[2] = newY
                            break
                        end
                    end
                end
            end
        end
    end
    if changed then
        state = delay(0.1, function(dt) applyGravity(nextState, dt) end)
    else
        state = nextState
    end
end

function findChain(startingBlock, seen)
    local chain = {}
    local fringe = {startingBlock}
    local color = startingBlock[3].color
    while #fringe > 0 do
        local x, y, current = unpack(table.remove(fringe))
        if current.color == color and not gridGet(seen, x, y) then
            table.insert(chain, {x, y, current})
            gridSet(seen, x, y, true)
            local neighbors = getNeighbors(grid, x, y)
            for dir, neighbor in pairs(neighbors) do
                if current.color == neighbor.blockInfo.color
                and not gridGet(seen, neighbor.x, neighbor.y) then
                    table.insert(fringe, {neighbor.x, neighbor.y, neighbor.blockInfo})
                end
            end
        end
    end
    return chain
end

function clearBlocks(dt)
    local changed = false
    local toRemove = {}
    for color, colorCrashBlocks in pairs(crashBlocks) do
        local seen = {}
        for i, colorCrashBlock in pairs(colorCrashBlocks) do
            local chain = findChain(colorCrashBlock, seen)
            if #chain > 1 then
                print(string.format("%s chain %s:", color, i))
                for j, block in pairs(chain) do
                    print(string.format("(%s, %s) color:%s, type:%s", block[1], block[2], block[3].color, block[3].type))
                    gridDel(grid, block[1], block[2])
                    if block[3].type == 'crash' then
                        table.insert(toRemove, {color, i})
                    end
                end
                changed = true
            end
        end
    end

    if changed then
        for i, keys in pairs(toRemove) do
            table.remove(crashBlocks[keys[1]], keys[2])
        end
        print("Cleared some blocks, applying gravity")
        state = function(dt)
            applyGravity(clearBlocks, dt)
        end
    else
        state = tryNew
    end
end

function getNeighbors(grid, x, y)
    local neighbors = {}
    local neighbor, newX, newY
    for _, dir in pairs(nextDir) do
        if dir == 'e' then
            newX = x + 1
            newY = y
        elseif dir == 's' then
            newX = x
            newY = y + 1
        elseif dir == 'w' then
            newX = x - 1
            newY = y
        elseif dir == 'n' then
            newX = x
            newY = y - 1
        end
        neighbor = gridGet(grid, newX, newY)
        if neighbor then
            neighbors[dir] = {
                x = newX,
                y = newY,
                blockInfo = neighbor
            }
        end
    end
    return neighbors
end

function getGridCoords(pair)
    local firstX, firstY = pair.x, pair.y
    local secondX, secondY, dir = pair.x, pair.y, pair.dir
    if dir == 'e' then
        secondX = secondX + 1
    elseif dir == 's' then
        secondY = secondY + 1
    elseif dir == 'w' then
        secondX = secondX - 1
    elseif dir == 'n' then
        secondY = secondY - 1
    end
    return firstX, firstY, secondX, secondY
end

function getPixelCoords(gridX, gridY)
    return gridX * gridInfo.tileWidth,
           gridY * gridInfo.tileHeight,
           gridInfo.tileWidth,
           gridInfo.tileHeight
end

function gridSet(grid, x, y, value)
    if grid[x] then
        grid[x][y] = value
    else
        grid[x] = {[y] = value}
    end
end

function gridGet(grid, x, y)
    if grid[x] then
        return grid[x][y]
    else
        return nil
    end
end

function gridDel(grid, x, y)
    if grid[x] then
        grid[x][y] = nil
    end
end

function love.load()
    math.randomseed(1)
    grid = {}
    mouseGridPos = {0, 0}
    colors = {
        'red', 'green', 'blue', 'yellow'
    }
    crashBlocks = {}
    for i, color in pairs(colors) do
        crashBlocks[color] = {}
    end
    colorVals = {
        red = {255, 0, 0, 255},
        green = {0, 255, 0, 255},
        blue = {0, 0, 255, 255},
        yellow = {255, 255, 0, 255},
    }
    types = {
        'normal',
        'crash',
    }
    currentPair = nil
    nextPair = newPair()
    gridInfo = {
        w = 6,
        h = 12,
        tileWidth = 32,
        tileHeight = 32,
    }
    nextDir = {
        e = 's',
        s = 'w',
        w = 'n',
        n = 'e',
    }
    startX = 3
    startY = 1
    startDir = 'e'
    state = tryNew
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

function drawBlock(gridX, gridY, blockInfo)
    local x, y, w, h = getPixelCoords(gridX, gridY)
    love.graphics.setColor(colorVal(blockInfo.color))
    if blockInfo.type == 'normal' then
        love.graphics.rectangle("fill", x, y, w, h)
    elseif blockInfo.type == 'crash' then
        love.graphics.circle("fill", x + w / 2, y + h / 2, w/ 2)
    end
end

function love.draw()
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
end
