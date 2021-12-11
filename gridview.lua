local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Screen = Device.screen
local Size = require("ui/size")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local logger = require("logger")

local GridRow = require("gridrow")
local GridSquare = require("gridsquare")
local GridClue = require("gridclue")

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
    self.square_margin = Size.border.window
    self.square_width = math.floor(
        (self.dimen.w - (2 * self.outer_padding) - (2 * self.inner_padding))
        / self.size.cols) - ((self.square_margin / 4) * (6)) -- 6 works here for some reason, although in my head
    -- (cont) it should be self.size.cols because that's what we're adjusting for.
    self.square_height = self.square_width
    -- Register the event listener
    self.ges_events.Tap = {
        GestureRange:new{
            ges = "tap",
            range = function()
                return self.dimen
            end,
        },
    }
end

function GridView:render()
    -- Build the row and add the squares.
    self.rows_view = VerticalGroup:new { border = 0 }
    for i, l in ipairs(self.grid) do
        local row =  self:buildRow(l)
        table.insert(self.rows_view, row)
    end
    -- Build the clue.
    self.grid_clue = GridClue:new{
        width = self.inner_dimen.w,
        height = self.square_height,
        clue_value = self.active_clue
    }
    -- Build the container.
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
            self.rows_view,
            self.grid_clue,
        }
    }
end

function GridView:onTap(_, ges)
    -- Temp for debuggery
    -- Find the square that's been tapped
    -- so we want to find the square
    -- and we can expedite that by getting the correct row, first,
    -- which is given by the square_height stuff... we will have to account for margins, too.
    -- self.square_margin
    -- self.square_height
    local y = ges.pos.y
    local x = ges.pos.x
    -- so, get the row number
    local row_num = math.ceil(x / (self.square_height))
    local col_num = math.ceil(y / self.square_width)
    -- If a callback's been set, we need to send back the
    -- coordinates so some genius can do something else.
    if self.on_tap_callback then
        self.on_tap_callback(row_num, col_num)
    end
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
            pos_x = col_num,
            pos_y = row_num,
            margin = self.square_margin,
            letter_value = square.letter,
            number_value = square.number,
        })
    end
    row:update()
    return row
end

return GridView
