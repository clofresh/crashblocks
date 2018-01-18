state = nil
crashBlocks = {}
currentPair = nil
nextPair = nil

function delay(delayTimeLimit, nextState)
    local delayTime = 0
    return function(dt)
        delayTime = delayTime + dt
        local pct = delayTime / delayTimeLimit
        if currentPair then
            currentPair.first.t = pct
            currentPair.second.t = pct
        end

        for x, ys in pairs(grid) do
            for y, blockInfo in pairs(ys) do
                if blockInfo.t then
                    blockInfo.t = pct
                end
            end
        end

        if delayTime > delayTimeLimit then
            state = nextState
            if currentPair then
                currentPair.first.prevX = nil
                currentPair.first.prevY = nil
                currentPair.first.t = nil
                currentPair.second.prevX = nil
                currentPair.second.prevY = nil
                currentPair.second.t = nil
            end
            for x, ys in pairs(grid) do
                for y, blockInfo in pairs(ys) do
                    if blockInfo.t then
                        if blockInfo.state == 'deleting' then
                            grid[x][y] = nil
                        else
                            blockInfo.t = nil
                        end
                    end
                end
            end
        end
    end
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
    local inputs = getInputs()
    if inputs.left then
        newX = currentPair.x - 1
        newY = currentPair.y
        newDir = currentPair.dir
        local firstPrevX, firstPrevY, secondPrevX, secondPrevY = getGridCoords(currentPair)
        currentPair.first.prevX = firstPrevX
        currentPair.first.prevY = firstPrevY
        currentPair.first.t = 0
        currentPair.second.prevX = secondPrevX
        currentPair.second.prevY = secondPrevY
        currentPair.second.t = 0
    elseif inputs.right then
        newX = currentPair.x + 1
        newY = currentPair.y
        newDir = currentPair.dir
        local firstPrevX, firstPrevY, secondPrevX, secondPrevY = getGridCoords(currentPair)
        currentPair.first.prevX = firstPrevX
        currentPair.first.prevY = firstPrevY
        currentPair.first.t = 0
        currentPair.second.prevX = secondPrevX
        currentPair.second.prevY = secondPrevY
        currentPair.second.t = 0
    elseif inputs.down then
        newX = currentPair.x
        newY = currentPair.y + 1
        newDir = currentPair.dir
        down = true
        local firstPrevX, firstPrevY, secondPrevX, secondPrevY = getGridCoords(currentPair)
        currentPair.first.prevX = firstPrevX
        currentPair.first.prevY = firstPrevY
        currentPair.first.t = 0
        currentPair.second.prevX = secondPrevX
        currentPair.second.prevY = secondPrevY
        currentPair.second.t = 0
    elseif inputs.rotate then
        newX = currentPair.x
        newY = currentPair.y
        newDir = nextDir[currentPair.dir]
        local _, _, secondPrevX, secondPrevY = getGridCoords(currentPair)
        currentPair.second.prevX = secondPrevX
        currentPair.second.prevY = secondPrevY
        currentPair.second.t = 0
    end

    if newX and canMove(newX, newY, newDir) then
        currentPair.x = newX
        currentPair.y = newY
        currentPair.dir = newDir
        local delayAmount
        if down then
            delayAmount = 0.025
        else
            delayAmount = 0.1
        end
        state = delay(delayAmount, inControl)
    elseif down then
        state = delay(0.1, function(dt)
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
        end)
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
                currentBlock.prevX = x
                currentBlock.prevY = y
                currentBlock.t = 0
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
        state = delay(0.25, function(dt)
            applyGravity(clearBlocks, dt)
        end)
    else
        state = tryNew
    end
end
