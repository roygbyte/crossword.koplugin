local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Screen = Device.screen
local Size = require("ui/size")
local Geom = require("ui/geometry")
local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local OverlapGroup = require("ui/widget/overlapgroup")
local VerticalGroup = require("ui/widget/verticalgroup")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local logger = require("logger")

local PuzzleRow = require("puzzlerow")
local PuzzleSquare = require("puzzlesquare")


local PuzzleView = InputContainer:new{
    width = nil,
    height = nil,
}

function PuzzleView:init()
    self.dimen = Geom:new{
        w = self.width or Screen:getWidth(),
        h = self.height or Screen:getHeight(),
    }
    self.outer_padding = Size.padding.large
    self.inner_padding = Size.padding.small
    self.inner_dimen = Geom:new{
        w = self.dimen.w - 2 * self.outer_padding,
        h = self.dimen.h - self.outer_padding, -- no bottom padding
    }
    self.content_width = self.inner_dimen.w
    -- The size of the game board
    self.grid = {
        cols = 10,
        rows = 10,
    }
    self.main_content = VerticalGroup:new{}

    -- self.populate_items
    -- Add the squares

    self.square_width = math.floor((self.dimen.w - (2 * self.outer_padding) - (2 * self.inner_padding)) / self.grid.cols)

    logger.dbg(self.square_width)
    
    local row = PuzzleRow:new{
        width = self.inner_dimen.w,
        height = 20
    }

    for index = 0, self.grid.cols, 1 do
        local square = PuzzleSquare:new{
            width = self.square_width,
            height = 20,
        }
        row:addSquare(square)
    end

    row:update()
       
    table.insert(self.main_content, row)
    
    
    local content = VerticalGroup:new{
            align = "left",
            self.main_content,
    }

    self[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        padding = self.outer_padding,
        padding_bottom = 0,
        margin = 0,
        bordersize = 0,
        background = Blitbuffer.COLOR_GRAY,
        content
    }        
end

return PuzzleView
