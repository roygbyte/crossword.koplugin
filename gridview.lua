local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Screen = Device.screen
local Size = require("ui/size")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local UIManager = require("ui/uimanager")
local logger = require("logger")

local SoftKeyboard = require("softkeyboard")
local GridRow = require("gridrow")
local GridSquare = require("gridsquare")
local GridClue = require("gridclue")
local GridInput = require("gridinput")

local GridView = InputContainer:new{
    width = nil,
    height = nil,
    size = {
        cols = nil,
        rows = nil,
    },
    on_tap_callback = nil
}

function GridView:init()
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
    -- The pixel dimensions of the squares. Calculate the initial width based on the size
    -- of the device and the number of columns. Then make a minor adjustment to account for
    -- the margins. To do this, divide margin in 4 and multiply by the number of columns.
    self.square_margin = 1 --Size.border.window
    self.square_width = math.floor(
        (self.dimen.w - (2 * self.outer_padding) - (2 * self.inner_padding))
        / self.size.cols)
    -- (cont) it should be self.size.cols because that's what we're adjusting for.
    self.square_height = self.square_width
    -- Computer the presumed height of the grid.
    self.grid_height = self.size.rows * self.square_height
    self:render()
end

function GridView:render()
    -- Build the row and add the squares.
    self.rows_view = VerticalGroup:new { border = 0 }
    for row_num, grid_row in ipairs(self.grid) do
        local row =  self:buildRow(grid_row, row_num)
        table.insert(self.rows_view, row)
    end
    -- Build the container.
    self[1] = FrameContainer:new{
        width = self.inner_dimen.w,
        height = self.inner_dimen.h,
        padding = self.outer_padding,
        padding_bottom = 0,
        margin = 0,
        bordersize = 0,
        background = Blitbuffer.COLOR_BLACK,
        VerticalGroup:new{
            align = "center",
            -- Add the rows vertical group.
            self.rows_view,
        }
    }
end
-- Method to help me remember to update only the parts of the grid that need to
-- be updated as the player interacts with the grid.
function GridView:updateGrid(grid)
    self.grid = grid
end

function GridView:updateClue(clue_value)
    self.active_clue = clue_value
end
-- Given a table containing letters, build a row containing
-- squares with said letters.
function GridView:buildRow(squares, row_num)
    local row = GridRow:new{
        width = self.inner_dimen.w,
        height = self.square_height,
    }
    for col_num, square in ipairs(squares) do
        row:addSquare(GridSquare:new{
            width = self.square_width,
            height = self.square_height,
            margin = self.square_margin,
            letter_value = square.letter,
            number_value = square.number,
            state = square.state,
            row_num = row_num, -- we pass the row and col so that
            col_num = col_num, -- the tap callback can propagate values back
            on_tap_callback = function(row_num, col_num)
                self.on_tap_callback(row_num, col_num)
            end
        })
    end
    row:update()
    return row
end

function GridView:addChars(chars)
    logger.dbg("GridView:addChars " .. chars)
    if self.add_chars_callback then
        self.add_chars_callback(chars)
    end
end

return GridView
