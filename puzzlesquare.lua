local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local FrameContainer = require("ui/widget/container/framecontainer")
local OverlapGroup = require("ui/widget/overlapgroup")
local TextWidget = require("ui/widget/textwidget")
local TextBoxWidget = require("ui/widget/textboxwidget")

local logger = require("logger")

local PuzzleSquare = InputContainer:new{
    letter_font_face = "infofont",
    letter_font_size = nil,
    number_font_face = "infont",
    number_font_size = nil,
    margin = nil,
    solve = nil,
}

function PuzzleSquare:init()
    -- Lazy check to see if solve is set.
    if not self.solve then
        logger.dbg("PuzzleSquare: solve not set for square")
        return
    end

    -- Set up the right bg color, letter, etc.
    local bg_color = self.solve.letter ~= "." and
        Blitbuffer.COLOR_WHITE or
        Blitbuffer.COLOR_BLACK
    local letter = self.solve.letter and
        self.solve.letter or
        ""
    local number = self.solve.number ~= 0 and
        tostring(self.solve.number) or
        ""

    self.letter_font_size = TextBoxWidget:getFontSizeToFitHeight(self.height, 1, 0.3)
    self.number_font_size = self.letter_font_size / 2

    -- This is the letter input by the player.
    self.letter = TextWidget:new{
        text = letter,
        face = Font:getFace(self.letter_font_face, self.letter_font_size),
        fgcolor = Blitbuffer.COLOR_BLACK,
        padding = 0,
        bold = true,
    }
    -- This is the number that corresponds to the question.
    -- Note that the number is not always set!
    self.number = TextWidget:new{
        text = number,
        face = Font:getFace(self.number_font_face, self.number_font_size),
        fgcolor = Blitbuffer.COLOR_BLACK,
        padding = 0,
        bold = true,
    }
    -- This is the container for the letter and number.
    self[1] = FrameContainer:new{
        width = self.width,
        height = self.height,
        color = Blitbuffer.COLOR_WHITE,
        background = bg_color,
        padding = 0,
        margin = self.margin or 0,
        bordersize = 0,
        OverlapGroup:new{
            dimen = { w = self.width },
            padding = 0,
            -- Keep the letter centered
            CenterContainer:new{
                dimen = Geom:new{
                    w = self.width,
                    h = self.height,
                },
                padding = 0,
                -- Add the letter
                self.letter,
            },
            -- Add the number
            self.number,
        },
    }
end

function PuzzleSquare:onTap()
    logger.dbg("TA________________P")
end

return PuzzleSquare
