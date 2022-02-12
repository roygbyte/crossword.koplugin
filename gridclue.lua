local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local FrameContainer = require("ui/widget/container/framecontainer")
local TextBoxWidget = require("ui/widget/textboxwidget")

local logger = require("logger")

local GridClue = InputContainer:new{
   height = nil,
   width = nil,
   clue_font_face = "infofont",
   clue_font_size = nil,
   clue_value = nil,
}

function GridClue:init()
   self.clue_font_size = TextBoxWidget:getFontSizeToFitHeight(self.height, 1, 0.3)

   self.clue_widget = TextBoxWidget:new{
      text = self.clue_value,
      face = Font:getFace(self.clue_font_face, self.clue_font_size),
      width = self.width,
      alignment = "center",
      fgcolor = Blitbuffer.COLOR_WHITE,
      bgcolor = Blitbuffer.COLOR_BLACK,
      padding = 0,
      bold = true,
   }

   self[1] = FrameContainer:new{
      width = self.width,
      height = self.height,
      padding = 0,
      margin = self.margin or 0,
      bordersize = 0,
      -- Keep the letter centered
      CenterContainer:new{
         dimen = Geom:new{
            w = self.width,
            h = self.height,
         },
         padding = 0,
         -- Add the letter
         self.clue_widget,
      },
   }
end

return GridClue
