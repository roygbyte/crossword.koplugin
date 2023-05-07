local Blitbuffer = require("ffi/blitbuffer")
local CenterContainer = require("ui/widget/container/centercontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local Font = require("ui/font")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local FrameContainer = require("ui/widget/container/framecontainer")
local LineWidget = require("ui/widget/linewidget")
local OverlapGroup = require("ui/widget/overlapgroup")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local logger = require("logger")
local ffi = require("ffi")

local Guess = require("guess")

local GridSquare = InputContainer:extend{
   height = nil,
   width = nil,
   margin = nil,
   letter_font_face = "infofont",
   letter_font_size = nil,
   number_font_face = "infont",
   number_font_size = nil,
   letter_value = nil,
   number_value = nil,
   dark_mode = nil,
}

function GridSquare:init()
   -- Set the dimensions.
   self.dimen = Geom:new{w = self.width, h = self.height}
   -- The state bg is used to indicate which region is activated (state 1),
   -- and which square is selected (state 2)
   local state_bg_color
   if self.state == "1" then
      state_bg_color = self.dark_mode and Blitbuffer.COLOR_GRAY_3 or Blitbuffer.COLOR_LIGHT_GRAY
   elseif self.state == "2" then
      state_bg_color = self.dark_mode and Blitbuffer.COLOR_GRAY_5 or Blitbuffer.COLOR_DARK_GRAY
   end

   local text_fg_color = self.dark_mode and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK
   local bg_default_on = self.dark_mode and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE
   local bg_default_off = self.dark_mode and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_BLACK
   -- Set up the right bg color, letter, etc.
   local bg_color = self.letter_value ~= "." and
      (state_bg_color and state_bg_color or bg_default_on) or
       bg_default_off
   -- The status bg is used to indicate whether the letter is correct or incorrect.
   local status_bg_color, status_height = 0
   if self.status == Guess.STATUS.CHECKED_INCORRECT then
      status_bg_color = self.dark_mode and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK
      status_height = 2
   elseif self.letter_value == "." then
       -- Set the color to black on non-letter squares
      local gray = ffi.typeof("Color8")(0x22)
      status_bg_color = self.dark_mode and gray or Blitbuffer.COLOR_BLACK
      text_fg_color = status_bg_color
      bg_color = status_bg_color
   else
       -- Everything else goes to default text color
      status_bg_color = (self.dark_mode and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK)
   end

   self.letter_font_size = TextBoxWidget:getFontSizeToFitHeight(self.height, 1, 0.3)
   self.number_font_size = self.letter_font_size / 2
   -- Maybe a letter input by the player.
   self.letter_widget = TextWidget:new{
      text = self.letter_value,
      face = Font:getFace(self.letter_font_face, self.letter_font_size),
      fgcolor = text_fg_color,
      padding = 0,
      bold = true,
   }
   -- Maybe a number that corresponds to a question.
   self.number_widget = TextWidget:new{
      text = self.number_value,
      face = Font:getFace(self.number_font_face, self.number_font_size),
      fgcolor = text_fg_color,
      padding = 0,
      bold = true,
   }
   -- Maybe a number that corresponds to a question.
   self.status_widget = LineWidget:new{
      background = status_bg_color,
      dimen = Geom:new{
         w = self.width - 5,
         h = status_height,
      }
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
      color = (self.dark_mode and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE),
      background = bg_color,
      padding = 0,
      margin = 0,
      margin_left = margin,
      bordersize = 0,
      color = border_color,
      OverlapGroup:new{
         dimen = { w = self.width - self.margin, h = self.height - self.margin },
         padding = 0,
         margin = 0,
         -- Add thet status indicator
         CenterContainer:new{
            dimen = Geom:new{
               w = self.width,
               h = self.height,
            },
            padding = 0,
            self.status_widget,
         },
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
