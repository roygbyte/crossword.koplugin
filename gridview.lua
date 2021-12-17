local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Screen = Device.screen
local Size = require("ui/size")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local FrameContainer = require("ui/widget/container/framecontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local Keyboard = require("ui/widget/virtualkeyboard")
local VerticalGroup = require("ui/widget/verticalgroup")
local UIManager = require("ui/uimanager")
local logger = require("logger")

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
        / self.size.cols) - ((self.square_margin))
    -- (cont) it should be self.size.cols because that's what we're adjusting for.
    self.square_height = self.square_width
    -- Computer the presumed height of the grid.
    self.grid_height = self.size.rows * self.square_height
end

function GridView:render()
    -- Build the row and add the squares.
    self.rows_view = VerticalGroup:new { border = 0 }
    for row_num, grid_row in ipairs(self.grid) do
        local row =  self:buildRow(grid_row, row_num)
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
-- Method to help me remember to update only the parts of the grid that need to
-- be updated as the player interacts with the grid.
function GridView:updateGrid(grid, active_clue)
    self.grid = grid
    self.active_clue = active_clue
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
            screen_zone = {
                ratio_x = (self.square_width * (col_num)) / self.dimen.w,
                ratio_y = (self.square_height * (row_num)) / self.dimen.h,
                ratio_w = ((self.square_width * (col_num)) + self.square_width ) / self.dimen.w,
                ratio_h = ((self.square_height * (row_num)) + self.square_height) / self.dimen.h,
            },
            on_tap_callback = function(row_num, col_num)
                self.on_tap_callback(row_num, col_num)
            end
        })
    end
    row:update()
    return row
end

function GridView:showKeyboard(should_show_keyboard)
    -- Init the keyboard if it doesn't exist.
    if not self.keyboard then
        self.keyboard = Keyboard:new{
            keyboard_layer = keyboard_layer,
            width = Screen:getWidth(),
            inputbox = self,
        }
        self.keyboard.ges_events.Tap = {
            GestureRange:new {
                ges = "tap",
                range = function()
                    self:showKeyboard(false)
                    return false
                end
            }
        }
    end
    -- Determine what to do based on the value passed to this method.
    if should_show_keyboard then
        Device:startTextInput()
        UIManager:show(self.keyboard)
        UIManager:setDirty(self.keyboard, function()
                return "ui", self.keyboard.dimen
        end)
    else
        Device:stopTextInput()
        UIManager:close(self.keyboard)
    end
    -- Return the keyboard in case we need to do something with it.
    return self.keyboard
end

function GridView:addChars(chars)
    if self.add_chars_callback then
        self.add_chars_callback(chars)
    end
end

return GridView
