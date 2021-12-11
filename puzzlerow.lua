local InputContainer = require("ui/widget/container/inputcontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local FrameContainer = require("ui/widget/container/framecontainer")

local Row = InputContainer:new{
    width = nil,
    height = nil,
    padding = nil,
}

function Row:init()
    self.squares = {}
end

function Row:addSquare(square)
    table.insert(self.squares, square)
end

function Row:update()
    local hori = HorizontalGroup:new{}

    for num, square in ipairs(self.squares) do
        table.insert(hori, square)
    end

    self[1] = FrameContainer:new{
        width = self.width,
        height = self.height,
        bordersize = 0,
        padding = 0,
        margin = 0,
        hori
    }
end

return Row
