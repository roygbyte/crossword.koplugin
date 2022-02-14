--[[--
   This plugin lets you play crosswords on your e-reader.

   @module koplugin.crossword
--]]--

local DataStorage = require("datastorage")
local Dispatcher = require("dispatcher")  -- luacheck:ignore
local InfoMessage = require("ui/widget/infomessage")
local LuaSettings = require("frontend/luasettings")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local LuaSettings = require("frontend/luasettings")
local logger = require("logger")
local json = require("json")
local util = require("util")
local _ = require("gettext")

local Solve = require("solve")
local GridView = require("gridview")
local GridInput = require("gridinput")
local GameView = require("gameview")
local History = require("history")
local Library = require("library")
local Puzzle = require("puzzle")

local Crossword = WidgetContainer:new{
   name = "crossword",
   settings = nil,
   settings_keys = {
      puzzle_library_dir = "puzzle_library_dir",
   },
   puzzle_library_dir = nil,
   active_puzzle = nil,
   ActiveGridView = nil,
}

function Crossword:init()
   self.ui.menu:registerToMainMenu(self)
end

function Crossword:addToMainMenu(menu_items)
   menu_items.crossword = {
      text = _("Crossword"),
      sub_item_table_func = function()
         return self:getSubMenuItems()
      end
   }
end

function Crossword:getSubMenuItems()
   self:lazyInitialization()
   -- This is the standard menu.
   local sub_menu_items = {
      {
         text = _("Puzzle Library"),
         callback = function()
            self:showLibraryView()
         end
      },
      {
         text = _("Settings"),
         sub_item_table = {
            {
               text = _("Set puzzles folder"),
               keep_menu_open = true,
               callback = function()
                  self:setPuzzlesDirectory()
               end
            }
         }
      }
   }
   -- If the user has started a puzzle, we'll add a new option to the menu.
   local history = History:new{}
   if #history:get() > 0 then
      local history_item = history:get()[1]
      table.insert(sub_menu_items, 1,
         {
            text = _(("Continue \"%s\""):format(history_item['puzzle_title'])),
            callback = function()
               local puzzle = Puzzle:loadById(history_item['puzzle_id'])            
               self:showGameView(puzzle)
            end
         }
      )
   end
   return sub_menu_items
end

function Crossword:lazyInitialization()
   -- Load the settings
   self.settings = LuaSettings:open(("%s/%s"):format(DataStorage:getSettingsDir(), "crossword_settings.lua"))
   -- Load the puzzle directory value
   self.puzzle_dir = self.settings_keys.puzzle_dir and
      self.settings:readSetting(self.settings_keys.puzzle_dir) or
      ("%s/plugins/crossword.koplugin/nyt_crosswords"):format(
         DataStorage:getFullDataDir())
end

function Crossword:setPuzzlesDirectory()
   local downloadmgr = require("ui/downloadmgr")
   downloadmgr:new{
      onConfirm = function(path)
         self.settings:saveSetting(self.settings_keys.puzzle_library_dir, ("%s/"):format(path))
         self.settings:flush()
      end
   }:chooseDir()
   -- After the user selects a directory, we will re-initialize the plugin so the
   -- directory variable is updated.
   self:lazyInitialization()
end
--[[--
Render the GameView for a given puzzle.
]]
function Crossword:showGameView(puzzle)
   local game_view = GameView:new{
      puzzle = puzzle
   }
   game_view:render()
   UIManager:show(game_view)
end

function Crossword:showLibraryView()
   local library = Library:new{
      puzzle_dir = self.puzzle_dir,
      onSelectPuzzle = function(item)
         local puzzle =  Puzzle:initializePuzzle(("%s/%s"):format(item.path_to_dir, item.filename))
         local history = History:new{}
         history:init()
         history:add(puzzle.id, puzzle.title)
         self:showGameView(puzzle)
   end}
   
   library:showDirectoryView(self.puzzle_dir)
end
--[[--

]]

return Crossword
