local Blitbuffer = require("ffi/blitbuffer")
local BottomContainer = require("ui/widget/container/bottomcontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local Device = require("device")
local Event = require("ui/event")
local FocusManager = require("ui/widget/focusmanager")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local ImageWidget = require("ui/widget/imagewidget")
local InputContainer = require("ui/widget/container/inputcontainer")
local KeyboardLayoutDialog = require("ui/widget/keyboardlayoutdialog")
local Size = require("ui/size")
local TextWidget = require("ui/widget/textwidget")
local TextBoxWidget = require("ui/widget/textboxwidget")
local time = require("ui/time")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local util = require("util")
local Screen = Device.screen

local keyboard_state = {
   force_current_layout = false, -- Set to true to get/set current layout (instead of default layout)
}

local VirtualKey = InputContainer:new{
   key = nil,
   icon = nil,
   label = nil,
   bold = nil,

   keyboard = nil,
   callback = nil,
   bg_color = nil,
   fg_color = nil,
   -- This is to inhibit the key's own refresh (useful to avoid conflicts on Layer changing keys)
   skiptap = nil,
   skiphold = nil,

   width = nil,
   height = math.max(Screen:getWidth(), Screen:getHeight())*0.33,
   bordersize = 0,
   focused_bordersize = Size.border.default,
   radius = 0,
   face = Font:getFace("infont"),
}

function VirtualKey:init()
   local label_font_size = G_reader_settings:readSetting("keyboard_key_font_size", DEFAULT_LABEL_SIZE)
   self.face = Font:getFace("infont", label_font_size)
   self.bold = G_reader_settings:isTrue("keyboard_key_bold")

   if self.label == "" then
      -- Register Del callback.
      self.callback = function () self.keyboard:delChar() end
   elseif self.label == "←" then
      -- Register left movement callback.
      self.callback = function() self.keyboard:leftChar() end
   elseif self.label == "→" then
      -- Register right movement callback.
      self.callback = function() self.keyboard:rightChar() end
   elseif self.label == "↑" then
      -- Register up movement callback.
      self.callback = function() self.keyboard:upLine() end
   elseif self.label == "↓" then
      -- Register down movement callback.
      self.callback = function() self.keyboard:downLine() end
   else
      self.callback = function () self.keyboard:addChar(self.key) end
      self.swipe_callback = function(ges)
         local key_string = self.key_chars[ges.direction] or self.key
         local key_function = self.key_chars[ges.direction.."_func"]

         if not key_function and key_string then
            if type(key_string) == "table" and key_string.key then
               key_string = key_string.key
            end
            self.keyboard:addChar(key_string)
         elseif key_function then
            key_function()
         end
      end
   end

   local label_widget
   label_widget = TextWidget:new{
      text = self.label,
      face = self.face,
      bold = self.bold or false,
      fgcolor = self.fg_color
   }
   -- Make long labels fit by decreasing font size
   local max_width = self.width - 2*self.bordersize - 2*Size.padding.small
   while label_widget:getWidth() > max_width do
      local new_size = label_widget.face.orig_size - 1
      label_widget:free()
      if new_size < 8 then break end -- don't go too small
      label_widget = TextWidget:new{
         text = self.label,
         face = Font:getFace(self.face.orig_font, new_size),
         bold = self.bold or false,
         fgcolor = self.fg_color
      }
   end

   self[1] = FrameContainer:new{
      margin = 0,
      bordersize = self.bordersize,
      background = self.bg_color or Blitbuffer.COLOR_WHITE,
      radius = 0,
      padding = 0,
      allow_mirroring = false,
      CenterContainer:new{
         dimen = Geom:new{
            w = self.width - 2*self.bordersize,
            h = self.height - 2*self.bordersize,
         },
         label_widget,
      },
   }
   self.dimen = Geom:new{
      w = self.width,
      h = self.height,
   }
   --self.dimen = self[1]:getSize()
   if Device:isTouchDevice() then
      self.ges_events = {
         TapSelect = {
            GestureRange:new{
               ges = "tap",
               range = self.dimen,
            },
         },
         HoldSelect = {
            GestureRange:new{
               ges = "hold",
               range = self.dimen,
            },
         },
         HoldReleaseKey = {
            GestureRange:new{
               ges = "hold_release",
               range = self.dimen,
            },
         },
         PanReleaseKey = {
            GestureRange:new{
               ges = "pan_release",
               range = self.dimen,
            },
         },
         SwipeKey = {
            GestureRange:new{
               ges = "swipe",
               range = self.dimen,
            },
         },
      }
   end
   self.flash_keyboard = G_reader_settings:nilOrTrue("flash_keyboard")
end

-- NOTE: We currently don't ever set want_flash to true (c.f., our invert method).
function VirtualKey:update_keyboard(want_flash, want_fast)
   -- NOTE: We mainly use "fast" when inverted & "ui" when not, with a cherry on top:
   --       we flash the *full* keyboard instead when we release a hold.
   if want_flash then
      UIManager:setDirty(self.keyboard, function()
            return "flashui", self.keyboard[1][1].dimen
      end)
   else
      local refresh_type = "ui"
      if want_fast then
         refresh_type = "fast"
      end
      -- Error gets thrown when first row of grid is touched. This line fixes that. Unsure
      -- about what side effects of this hack could be...
      if self[1].dimen then
         -- Only repaint the key itself, not the full board...
         UIManager:widgetRepaint(self[1], self[1].dimen.x, self[1].dimen.y)
         UIManager:setDirty(nil, function()
               logger.dbg("update key region", self[1].dimen)
               return refresh_type, self[1].dimen
         end)
      end
   end
end

function VirtualKey:onFocus()
   self[1].inner_bordersize = self.focused_bordersize
end

function VirtualKey:onUnfocus()
   self[1].inner_bordersize = 0
end

function VirtualKey:onTapSelect(skip_flash)
   Device:performHapticFeedback("KEYBOARD_TAP")
   -- just in case it's not flipped to false on hold release where it's supposed to
   self.keyboard.ignore_first_hold_release = false
   if self.flash_keyboard and not skip_flash and not self.skiptap then
      self:invert(true)
      UIManager:forceRePaint()
      UIManager:yieldToEPDC()

      self:invert(false)
      if self.callback then
         self.callback()
      end
      UIManager:forceRePaint()
   else
      if self.callback then
         self.callback()
      end
   end
   return true
end

function VirtualKey:onHoldSelect()
   Device:performHapticFeedback("LONG_PRESS")
   -- No visual feedback necessary if we're going to show a popup on top of the key ;).
   if self.flash_keyboard and not self.skiphold and not self.hold_cb_is_popup then
      self:invert(true)
      UIManager:forceRePaint()
      UIManager:yieldToEPDC()

      -- NOTE: We do *NOT* set hold to true here,
      --       because some mxcfb drivers apparently like to merge the flash that it would request
      --       with the following key redraw, leading to an unsightly double flash :/.
      self:invert(false)
      if self.hold_callback then
         self.hold_callback()
      end
      UIManager:forceRePaint()
   else
      if self.hold_callback then
         self.hold_callback()
      end
   end
   return true
end

function VirtualKey:onSwipeKey(arg, ges)
   Device:performHapticFeedback("KEYBOARD_TAP")
   if self.flash_keyboard and not self.skipswipe then
      self:invert(true)
      UIManager:forceRePaint()
      UIManager:yieldToEPDC()

      self:invert(false)
      if self.swipe_callback then
         self.swipe_callback(ges)
      end
      UIManager:forceRePaint()
   else
      if self.swipe_callback then
         self.swipe_callback(ges)
      end
   end
   return true
end

function VirtualKey:onHoldReleaseKey()
   if self.ignore_key_release then
      self.ignore_key_release = nil
      return true
   end
   Device:performHapticFeedback("LONG_PRESS")
   if self.keyboard.ignore_first_hold_release then
      self.keyboard.ignore_first_hold_release = false
      return true
   end
   self:onTapSelect()
   return true
end

function VirtualKey:onPanReleaseKey()
   if self.ignore_key_release then
      self.ignore_key_release = nil
      return true
   end
   Device:performHapticFeedback("LONG_PRESS")
   if self.keyboard.ignore_first_hold_release then
      self.keyboard.ignore_first_hold_release = false
      return true
   end
   self:onTapSelect()
   return true
end

-- NOTE: We currently don't ever set hold to true (c.f., our onHoldSelect method)
function VirtualKey:invert(invert, hold)
   if invert then
      self[1].inner_bordersize = self.focused_bordersize
   else
      self[1].inner_bordersize = 0
   end
   self:update_keyboard(hold, false)
end

local VirtualKeyboard = InputContainer:new{
   name = "VirtualKeyboard",
   clue_value = nil,
   -- modal = true,
   disable_double_tap = true,
   inputbox = nil,
   KEYS = {}, -- table to store layouts
   keyboard_layer = 1,
   layout = {},
   height = nil,
   keys_height = nil,
   default_label_size = DEFAULT_LABEL_SIZE,
   bordersize = Size.border.default,
   padding = 0,
   key_padding = Size.padding.small,
}

function VirtualKeyboard:init()
   if self.uwrap_func then
      self.uwrap_func()
      self.uwrap_func = nil
   end
   -- Load the custom keyboard layout for Crossword.
   local keyboard = require("softkeyboard_layout")
   self.KEYS = keyboard.keys
   self.width = Screen:getWidth()
   -- Override user keyboard settings. Set a custom, narrow key height.
   local keys_height = 60
   self.rows = #self.KEYS + 1 -- Should probably make the +1 conditional. Anyways, its' there to
   -- ... account for the clue.
   self.height = Screen:scaleBySize(keys_height * (self.rows))
   self.keyboard_layer = self.keyboard_layour or 1
   -- Calculate key height, width, and paddings.
   self.base_key_width = math.floor((self.width - (#self.KEYS[1] + 1) *
         self.key_padding - 2*self.padding)/#self.KEYS[1])
   self.base_key_height = math.floor((self.height - (self.rows + 1) *
         self.key_padding - 2*self.padding)/self.rows)
   self:render()
   -- Not sure what this does.
   self.tap_interval_override = G_reader_settings:readSetting("ges_tap_interval_on_keyboard", 0)
   self.tap_interval_override = time.ms(self.tap_interval_override)
end

function VirtualKeyboard:render(keys_layout, clue_layout)
   -- Build the keys and the clue.
   local clue_layout = self:buildClue(self.clue_value or "")
   local keys_layout = self:buildKeys()
   self:free() -- free previous keys' TextWidgets
   self.layout = {}
   -- Add the keys to the frame.
   local keyboard_frame = FrameContainer:new{
      margin = 0,
      bordersize = Size.border.default,
      background = self.dark_mode and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_LIGHT_GRAY,
      radius = 0,
      padding = self.padding,
      allow_mirroring = false,
      CenterContainer:new{
         dimen = Geom:new{
            w = self.width - 2*Size.border.default - 2*self.padding,
            h = self.height - 2*Size.border.default - 2*self.padding,
         },
         VerticalGroup:new{
            allow_mirroring = false,
            clue_layout,
            keys_layout,
         }
      }
   }
   -- Fetch and set the keyboard's dimensions. This is used for calculating gesture areas.
   self.dimen = keyboard_frame:getSize()
   -- Put the keyboard where the Widget Container knows to look to render it.
   self[1] = keyboard_frame
end

function VirtualKeyboard:updateClue(clue_value)
   self.clue_value = clue_value or ""
end

--- @todo: build this to be where the hint lives. Put those fancy arrows in here, too, so
-- a person can move between clues.
function VirtualKeyboard:buildClue(clue_value)
   local letter_font_size = TextBoxWidget:getFontSizeToFitHeight(self.base_key_height, 1, 0.3)
   local vertical_group = VerticalGroup:new{ allow_mirroring = false }
   local horizontal_group = HorizontalGroup:new{ allow_mirroring = false }
   local h_key_padding = HorizontalSpan:new{width = self.key_padding}
   local v_key_padding = VerticalSpan:new{width = self.key_padding}

   local bg_color = self.dark_mode and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_LIGHT_GRAY
   local fg_color = self.dark_mode and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK

   local virtual_key_left = VirtualKey:new{
      key = "←",
      key_chars = {"←"},
      label = "←",
      bg_color = bg_color,
      fg_color = fg_color,
      keyboard = self,
      width = self.base_key_width,
      height = self.base_key_height,
   }
   local virtual_key_right = VirtualKey:new{
      key = "→",
      key_chars = {"→"},
      label = "→",
      bg_color = bg_color,
      fg_color = fg_color,
      keyboard = self,
      width = self.base_key_width,
      height = self.base_key_height,
   }
   local clue_row_width = self.width - (self.base_key_width * 2) - (self.key_padding * 2)
   local clue_row = VirtualKey:new{
      key = "direction",
      key_chars = {"direction"},
      label = clue_value,
      bg_color = bg_color,
      fg_color = fg_color,
      keyboard = self,
      width = clue_row_width,
      height = self.base_key_height,
   }

   -- table.insert(horizontal_group, h_key_padding)
   table.insert(horizontal_group, virtual_key_left)
   table.insert(horizontal_group, clue_row)
   table.insert(horizontal_group, virtual_key_right)
   -- table.insert(horizontal_group, h_key_padding)
   table.insert(vertical_group, horizontal_group)
   table.insert(vertical_group, v_key_padding)

   return vertical_group
end

function VirtualKeyboard:buildKeys()
   -- Calculate key height, width, and paddings.
   local h_key_padding = HorizontalSpan:new{width = self.key_padding}
   local v_key_padding = VerticalSpan:new{width = self.key_padding}
   local vertical_group = VerticalGroup:new{ allow_mirroring = false }

   local bg_color = self.dark_mode and Blitbuffer.COLOR_BLACK or Blitbuffer.COLOR_WHITE
   local fg_color = self.dark_mode and Blitbuffer.COLOR_WHITE or Blitbuffer.COLOR_BLACK
   -- Loop through each key row.
   for i = 1, #self.KEYS do
      local horizontal_group = HorizontalGroup:new{ allow_mirroring = false }
      local layout_horizontal = {}
      -- Loop through each key item and create the VirtualKey widget.
      for j = 1, #self.KEYS[i] do
         local key
         local key_chars = self.KEYS[i][j][self.keyboard_layer]
         local label
         local alt_label
         local width_factor
         if type(key_chars) == "table" then
            key = key_chars[1]
            label = key_chars.label
            alt_label = key_chars.alt_label
            width_factor = key_chars.width
         else
            key = key_chars
            key_chars = nil
         end
         width_factor = width_factor or self.KEYS[i][j].width or self.KEYS[i].width or 1.0
         local key_width = math.floor((self.base_key_width + self.key_padding) * width_factor)
            - self.key_padding
         local key_height = self.base_key_height
         label = label or self.KEYS[i][j].label or key
         local virtual_key = VirtualKey:new{
            key = key,
            key_chars = key_chars,
            icon = self.KEYS[i][j].icon,
            label = label,
            bg_color = bg_color,
            fg_color = fg_color,
            alt_label = alt_label,
            bold = self.KEYS[i][j].bold,
            keyboard = self,
            width = key_width,
            height = key_height,
         }
         if not virtual_key.key_chars then
            virtual_key.swipe_callback = nil
         end
         table.insert(horizontal_group, virtual_key)
         table.insert(layout_horizontal, virtual_key)
         if j ~= #self.KEYS[i] then
            table.insert(horizontal_group, h_key_padding)
         end
      end
      -- Add each group of keys to the vertical group.
      table.insert(vertical_group, horizontal_group)
      table.insert(self.layout, layout_horizontal)
      if i ~= #self.KEYS then
         table.insert(vertical_group, v_key_padding)
      end
   end
   return vertical_group
end

-- function VirtualKeyboard:_refresh(want_flash, fullscreen)
--     local refresh_type = "ui"
--     if want_flash then
--         refresh_type = "flashui"
--     end
--     if fullscreen then
--         UIManager:setDirty("all", refresh_type)
--         return
--     end
--     UIManager:setDirty(self, function()
--         return refresh_type, self[1][1].dimen
--     end)
-- end

function VirtualKeyboard:addChar(key)
   self.inputbox:addChars(key)
end

function VirtualKeyboard:delChar()
   self.inputbox:delChar()
end

function VirtualKeyboard:leftChar()
   self.inputbox:leftChar()
end

function VirtualKeyboard:rightChar()
   self.inputbox:rightChar()
end

function VirtualKeyboard:upLine()
   self.inputbox:upLine()
end

function VirtualKeyboard:downLine()
   self.inputbox:downLine()
end

return VirtualKeyboard
