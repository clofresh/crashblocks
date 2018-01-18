grid = {}
gridInfo = {
    w = 8,
    h = 14,
    tileWidth = 128,
    tileHeight = 128,
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

function getPixelCoords(gridX, gridY, prevGridX, prevGridY, t)
    if prevGridX ~= nil and prevGridY ~= nil and t ~= nil then
        local dx = gridX - prevGridX
        local dy = gridY - prevGridY
        local mag = math.sqrt(dx * dx + dy * dy)
        if mag > 0 then
            dx = dx / mag * t
            dy = dy / mag * t
        end
        return (prevGridX + dx) * gridInfo.tileWidth,
           (prevGridY + dy) * gridInfo.tileHeight,
           gridInfo.tileWidth,
           gridInfo.tileHeight
    else
        return gridX * gridInfo.tileWidth,
           gridY * gridInfo.tileHeight,
           gridInfo.tileWidth,
           gridInfo.tileHeight
   end
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
        grid[x][y].prevX = nil
        grid[x][y].prevY = nil
        grid[x][y].state = 'deleting'
        grid[x][y].t = 0
    end
end
