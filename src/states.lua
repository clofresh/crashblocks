state = nil
crashBlocks = {}
currentPair = nil
nextPair = nil

function delay(delayTimeLimit, nextState)
    local delayTime = 0
    return function(dt)
        delayTime = delayTime + dt
        if delayTime > delayTimeLimit then
            state = nextState
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
            delayAmount = 0.025
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
