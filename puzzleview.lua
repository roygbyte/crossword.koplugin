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
    size = {
        cols = nil,
        rows = nil,
    }
}

function PuzzleView:init()

    -- Temp! This will be the puzzle object, eventually.
    local letters = {
        {"A","B",".","C","D","E"},
        {"B",".","C","D","E","C"},
    }

    local puzzle_cols = #letters[1]
    local puzzle_rows = #letters

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
    -- The grid dimensions of the puzzle.
    --self.grid = {
    --    cols = puzzle_cols,
    --    rows = puzzle_rows,
    --}
    -- The pixel dimensions of the squares. Calculate the initial width based on the size
    -- of the device and the number of columns. Then make a minor adjustment to account for
    -- the margins. To do this, divide margin in 4 and multiply by the number of columns.
    self.square_margin = Size.border.window
    self.square_width = math.floor(
        (self.dimen.w - (2 * self.outer_padding) - (2 * self.inner_padding))
        / self.size.cols) - ((self.square_margin / 4) * (puzzle_cols))
    self.square_height = self.square_width

    ------------------
    -- Add the squares
    self.rows_group = VerticalGroup:new{ border = 0 }

    for i, l in ipairs(self.grid) do
        table.insert(self.rows_group, self:buildRow(l))
    end

    ---------------
    -- Build the container

    self[1] = FrameContainer:new{
        width = self.dimen.w,
        height = self.dimen.h,
        padding = self.outer_padding,
        padding_bottom = 0,
        margin = 0,
        bordersize = 0,
        background = Blitbuffer.COLOR_BLACK,
        VerticalGroup:new{
            align = "center",
            background = Blitbuffer.COLOR_GRAY,
            -- Add the rows vertical group.
            self.rows_group,
        }
    }
end

function PuzzleView:create()

end

-- Given a table containing letters, build a row containing
-- squares with said letters.
function PuzzleView:buildRow(squares)
    local row = PuzzleRow:new{
        width = self.inner_dimen.w,
        height = self.square_height,
    }
    for i, square in ipairs(squares) do
        -- This needs a better name. It should be a combination of the user's input,
        -- plus also like the square solve thing (hints, etc.)
        local solve = {
            letter = square.letter,
            number = square.number,
        }
        local square = PuzzleSquare:new{
            width = self.square_width,
            height = self.square_height,
            margin = self.square_margin,
            solve = solve,
        }
        row:addSquare(square)
    end
    row:update()
    return row
end

return PuzzleView
