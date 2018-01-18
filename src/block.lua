colors = {
    'red', 'green', 'blue', 'yellow'
}
colorVals = {
    red = {255, 0, 0, 255},
    green = {0, 255, 0, 255},
    blue = {0, 0, 255, 255},
    yellow = {255, 255, 0, 255},
}

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

function drawBlock(gridX, gridY, blockInfo)
    local x, y, w, h = getPixelCoords(gridX, gridY,
        blockInfo.prevX, blockInfo.prevY, blockInfo.t)
    local colorOriginal = colorVals[blockInfo.color]
    local color = {colorOriginal[1], colorOriginal[2], colorOriginal[3], colorOriginal[4]}
    if blockInfo.state == 'deleting' then
        color[4] = (1 - blockInfo.t) * 255
    end
    love.graphics.setColor(color)
    if blockInfo.type == 'normal' then
        love.graphics.rectangle("fill", x, y, w, h)
    elseif blockInfo.type == 'crash' then
        love.graphics.circle("fill", x + w / 2, y + h / 2, w/ 2)
    end
end
