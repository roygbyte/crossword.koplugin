local BD = require("ui/bidi")
local Blitbuffer = require("ffi/blitbuffer")
local ButtonDialog = require("ui/widget/buttondialog")
local CenterContainer = require("ui/widget/container/centercontainer")
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
local _ = require("gettext")
local ffi = require("ffi")

local GridView = require("gridview")
local SoftKeyboard = require("softkeyboard")
local Solve = require("solve")

local GameView = InputContainer:new{
   width = nil,
   height = nil,
   puzzle = nil,
   active_direction = Solve.DOWN,
   active_row_num = nil,
   active_col_num = nil,
   dark_mode = nil,
}

function GameView:init()
   self.dimen = Geom:new{
      w = self.width or Screen:getWidth(),
      h = self.height or Screen:getHeight(),
   }
   -- Initialize the grid.
   self.puzzle:getGrid()
   self.active_row_num = 1
   self.active_col_num = 1
   self.active_clue = self.puzzle:getClueByPos(1,1, self.active_direction) or ""
   -- Set the initial active direction
   self.puzzle:setActiveDirection(Solve.DOWN)
   -- Initialize gesture events.
   if Device:isTouchDevice() then
      self.ges_events.Swipe = {
         GestureRange:new{
            ges = "swipe",
            range = self.dimen,
         }
      }
   end
end

function GameView:render()
   -- Build the keyboard.
   self.keyboard_view = SoftKeyboard:new{
      width = Screen:getWidth(),
      clue_value = self.active_clue,
      inputbox = self,
      dark_mode = self.dark_mode,
   }
   -- Calculate grid height. Note that grid_height should not exceed screen width.
   local screen_h_minus_keyboard_h = Screen:getHeight() - self.keyboard_view.dimen.h
   local grid_height = screen_h_minus_keyboard_h < Screen:getWidth() and
      screen_h_minus_keyboard_h or
      Screen:getWidth()
   local grid_width = grid_height
   self.grid_view = GridView:new{
      width = grid_width,
      height = grid_height,
      size = {
         cols = self.puzzle.size.cols,
         rows = self.puzzle.size.rows
      },
      grid = self.puzzle:getGrid(),
      dark_mode = self.dark_mode,
      on_tap_callback = function(row_num, col_num)
         local maybe_square_index = self.puzzle:getIndexFromCoordinates(row_num, col_num)
         if not self.puzzle:getSolveByIndex(maybe_square_index) then
            return
         end
         self.active_row_num = row_num
         self.active_col_num = col_num
         self:refreshGameView()
      end,
   }
   -- Build the container.

   local gray = ffi.typeof("Color8")(0x22)

   self[1] = FrameContainer:new{
      width = self.dimen.w,
      height = self.dimen.h,
      padding = 0,
      margin = 0,
      bordersize = 0,
      background = (self.dark_mode and gray or Blitbuffer.COLOR_BLACK),
      VerticalGroup:new{
         align = "center",
         background = (self.dark_mode and gray or Blitbuffer.COLOR_GRAY),
         CenterContainer:new{
            dimen = Geom:new{
               w = self.dimen.w,
               h = screen_h_minus_keyboard_h,
            },
            padding = 0,
            self.grid_view,
         },
         self.keyboard_view,
      }
   }
   self:refreshGameView()
end

function GameView:refreshGameView()
   -- Refresh is basically called after every action, so makes sense
   -- to have the save method called from here.
   local clue_value = self.puzzle:getClueByPos(self.active_row_num, self.active_col_num, self.active_direction)
   if not clue_value then
      self.puzzle:resetActiveSquare()
   else
      self.puzzle:setActiveSquare(self.active_row_num, self.active_col_num)
   end

   self.grid_view:updateGrid(self.puzzle:getGrid())
   self.keyboard_view:updateClue(clue_value)

   self.grid_view:render()
   self.keyboard_view:render()
   -- Setting it dirty works. I don't know enough about UIManager to understand why
   -- UIManager:show doesn't work.
   UIManager:setDirty(self, "ui")
end

function GameView:addChars(chars)
   logger.dbg(chars)
   --- @todo: move the direction toggle into its own method thing. This is a sloppy
   -- hack to make work, and I would like to do better.
   if chars == "direction" then
      self:toggleDirection()
   else
      self.puzzle:setLetterForGuess(chars, self.puzzle:getActiveSquare())
      -- Advance the pointer
      self:movePointer(1)
      self:refreshGameView()
   end
   return true
end

-- This method (and its sister method, GameView:leftChar) should advance the player's active
-- square to the next square that belongs to the next clue. The clue should advance either
--down or across depending on which direction is active.
function GameView:rightChar()
   local row, col = self.puzzle:getNextCluePos(self.active_row_num, self.active_col_num, self.active_direction)
   self.active_row_num = row
   self.active_col_num = col
   self:refreshGameView()
end

function GameView:leftChar()
   if (isTap == 1 and self.active_row_num == 1 and self.active_col_num == 1) then
      isTap = 0
      return
   elseif (isTap == 1 and self.puzzle.size.cols > 15 and self.active_row_num < 3 and self.active_col_num == 1) then
      isTap = 0
      return
   end
   isTap = 0
   local row, col = self.puzzle:getPrevCluePos(self.active_row_num, self.active_col_num, self.active_direction)
   self.active_row_num = row
   self.active_col_num = col
   self:refreshGameView()
end
-- This method should be written so as to advance the pointer to the next
-- solve, and not the next square.
-- Can reliably accept 1 or -1. Doesn't work well for other numbers.
function GameView:movePointer(steps)
   -- Temp variables for the row and col nums are used here because the values produced by the
   -- next if/else block results in two courses of actions.
   local temp_row_num = self.active_row_num
   local temp_col_num = self.active_col_num

   if self.active_direction == Solve.DOWN then
      temp_row_num = temp_row_num + steps
   elseif self.active_direction == Solve.ACROSS then
      temp_col_num = temp_col_num + steps
   end
   -- Check to see if advancement landed on a non-active grid square.
   -- If it did, then move the user to the next solve.
   if steps >= 1 and (temp_row_num > self.puzzle.size.rows or
      temp_col_num > self.puzzle.size.cols or
      not self.puzzle:getClueByPos(temp_row_num, temp_col_num, self.active_direction)) then
      self:rightChar()
      steps = steps - 1
      self:movePointer(steps)
   elseif steps <= -1 and (temp_row_num < 1 or
      temp_col_num < 1 or
      not self.puzzle:getClueByPos(temp_row_num, temp_col_num, self.active_direction)) then
      self:leftChar()
      steps = steps + 1
      self:movePointer(steps)
   else
      self.active_row_num = temp_row_num
      self.active_col_num = temp_col_num
   end
end

-- This method should 1) delete the character in the active square, 2) move to the previous
-- square in the row or column.
function GameView:delChar()
   if self.puzzle:getLetterForSquare(self.puzzle:getActiveSquare()) ~= "" then
      self.puzzle:setLetterForGuess("", self.puzzle:getActiveSquare())
   else
      self:movePointer(-1)
   end
   self:refreshGameView()
end

function GameView:toggleDirection()
   if self.active_direction == Solve.DOWN then
      self.active_direction = Solve.ACROSS
   elseif self.active_direction == Solve.ACROSS then
      self.active_direction = Solve.DOWN
   end
   self.puzzle:setActiveDirection(self.active_direction)
   self:refreshGameView()
end

function GameView:onSwipe(arg, ges_ev)
   local direction = BD.flipDirectionIfMirroredUILayout(ges_ev.direction)
   if direction == "south" then
      -- See readerhighlight.lua for more ideas about how to use ButtonDialog.
      self.puzzle:save()
      self:showGameMenu()
   elseif direction == "east" then
      self:leftChar()
   elseif direction == "west" then
      self:rightChar()
   end
end

function GameView:showGameMenu()
   local game_dialog
   local game_view = self
   -- @todo: add the puzzle's title to this menu?
   game_dialog = ButtonDialog:new{
      buttons = {
         {
            {
               text = _("Check Square"),
               callback = function()
                  self.puzzle:checkSquare(self.active_row_num, self.active_col_num)
                  UIManager:close(game_dialog)
                  self:refreshGameView()
               end,
            },
            {
               text = _("Reveal Square"),
               callback = function()
                  self.puzzle:revealSquare(
                     self.puzzle:getIndexFromCoordinates(self.active_row_num, self.active_col_num)
                  )
                  UIManager:close(game_dialog)
                  self:refreshGameView()
               end,
            },
         },
         {
             {
               text = _("Check Puzzle"),
               callback = function()
                  UIManager:close(game_dialag)
                  self.puzzle:checkPuzzle()
                  self:refreshGameView()
               end,
            },
            {
               text = _("Remove Incorrect"),
               callback = function()
                   self.puzzle:removeIncorrectGuesses()
                   UIManager:close(game_dialog)
                   self:refreshGameView()
               end,
            },
         },
         {
             {
                 text = _("Toggle Dark Mode"),
                 callback = function()
                     if self.dark_mode then
                         self.dark_mode = false
                     else
                         self.dark_mode = true
                     end
                     self:render()
                     UIManager:close(game_dialog)
                 end,
             },
         },
         {
            {
               text = _("Saved!"),
               enabled = false,
               callback = function()
                   -- Nothing to show
               end,
            },
            {
               text = _("Exit"),
               callback = function()
                  UIManager:close(game_dialog)
                  UIManager:close(game_view)
                  UIManager:setDirty(nil, "full")
               end,
            },
         }
      },
      tap_close_callback = function()
         UIManager:close(game_dialog)
      end,
   }
   UIManager:show(game_dialog)
end

function GameView:onKeyPress(key)
   if key["RPgFwd"] then
      self:rightChar()
   elseif key["RPgBack"] then
      self:leftChar()
   end
end

return GameView
