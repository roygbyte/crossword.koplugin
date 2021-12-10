local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local FrameContainer = require("ui/widget/container/framecontainer")
local TextWidget = require("ui/widget/textwidget")

local logger = require("logger")

local PuzzleSquare = InputContainer:new{
    font_face = "xx_smallinfofont",
    font_size = 10,
}

function PuzzleSquare:init()
    self.letter = TextWidget:new{
        text = "A",
        face = Font:getFace(self.font_face, self.font_size),
        fgcolor = Blitbuffer.COLOR_BLACK,
        padding = 0,
        bold = true,
    }

    logger.dbg(self.width)

    self[1] = FrameContainer:new{
        width = self.width,
        height = self.height,
        color = Blitbuffer.COLOR_WHITE,
        padding = 0,
        CenterContainer:new{
            dimen = Geom:new{
                w = self.width,
                h = self.height,
            },
            self.letter,
        }
    }
end

return PuzzleSquare
