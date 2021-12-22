local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local FrameContainer = require("ui/widget/container/framecontainer")
local OverlapGroup = require("ui/widget/overlapgroup")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local TextBoxWidget = require("ui/widget/textboxwidget")

local logger = require("logger")

local GridSquare = InputContainer:new{
    height = nil,
    width = nil,
    margin = nil,
    letter_font_face = "infofont",
    letter_font_size = nil,
    number_font_face = "infont",
    number_font_size = nil,
    letter_value = nil,
    number_value = nil,
}

function GridSquare:init()
    -- Set the dimensions.
    self.dimen = Geom:new{w = self.width, h = self.height}
    -- The state bg is used to indicate which region is activated (state 1),
    -- and which square is selected (state 2)
    local state_bg_color
    if self.state == "1" then
        state_bg_color = Blitbuffer.COLOR_LIGHT_GRAY
    elseif self.state == "2" then
        state_bg_color = Blitbuffer.COLOR_DARK_GRAY
    end
    -- Set up the right bg color, letter, etc.
    local bg_color = self.letter_value ~= "." and
        (state_bg_color and state_bg_color or Blitbuffer.COLOR_WHITE) or
        Blitbuffer.COLOR_BLACK

    self.letter_font_size = TextBoxWidget:getFontSizeToFitHeight(self.height, 1, 0.3)
    self.number_font_size = self.letter_font_size / 2

    -- Maybe a letter input by the player.
    self.letter_widget = TextWidget:new{
        text = self.letter_value,
        face = Font:getFace(self.letter_font_face, self.letter_font_size),
        fgcolor = Blitbuffer.COLOR_BLACK,
        padding = 0,
        bold = true,
    }
    -- Maybe a number that corresponds to a question.
    self.number_widget = TextWidget:new{
        text = self.number_value,
        face = Font:getFace(self.number_font_face, self.number_font_size),
        fgcolor = Blitbuffer.COLOR_BLACK,
        padding = 0,
        bold = true,
    }
    -- Register the event listener
    self.ges_events.Tap = {
        GestureRange:new{
            ges = "tap",
            range = function()
                return self.dimen
            end
        },
    }
    -- This is the container for the letter and number.
    self[1] = FrameContainer:new{
        width = self.width - self.margin * 2,
        height = self.height - self.margin * 2,
        color = Blitbuffer.COLOR_WHITE,
        background = bg_color,
        padding = 0,
        margin = 0,
        margin_left = margin,
        --margin = self.margin or 0,
        bordersize = 0,
        OverlapGroup:new{
            dimen = { w = self.width - self.margin, h = self.height - self.margin },
            padding = 0,
            margin = 0,
            -- Keep the letter centered
            CenterContainer:new{
                dimen = Geom:new{
                    w = self.width,
                    h = self.height,
                },
                padding = 0,
                -- Add the letter
                self.letter_widget,
            },
            -- Add the number
            self.number_widget,
        },
    }
end

function GridSquare:onTap(_, ges)
    if self.on_tap_callback then
        self.on_tap_callback(self.row_num, self.col_num)
    end
end

function GridSquare:onInputEvent()
    logger.dbg("hiii")
end

return GridSquare
