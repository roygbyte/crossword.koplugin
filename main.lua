--[[--
This is a debug plugin to test Plugin functionality.

@module koplugin.HelloWorld
--]]--

-- This is a debug plugin, remove the following if block to enable it
local DataStorage = require("datastorage")
local Dispatcher = require("dispatcher")  -- luacheck:ignore
local InfoMessage = require("ui/widget/infomessage")
local LuaSettings = require("frontend/luasettings")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local LuaSettings = require("frontend/luasettings")
local logger = require("logger")
local json = require("json")
local _ = require("gettext")

local Solve = require("solve")
local GridView = require("gridview")

local Crossword = WidgetContainer:new{
    name = "crossword",
    settings = nil,
    settings_keys = {
        puzzles_dir = "puzzles_dir"
    },
    puzzles_dir = nil,
    active_puzzle = nil,
    ActiveGridView = nil,
}

function Crossword:init()
    self.ui.menu:registerToMainMenu(self)
end

function Crossword:addToMainMenu(menu_items)
    menu_items.crossword = {
        text = _("Crossword"),
        -- a callback when tapping
        sub_item_table_func = function()
            return self:getSubMenuItems()
        end
    }
end

function Crossword:getSubMenuItems()
    self:lazyInitialization()
    return {
        {
            text = _("Play"),
            callback = function()
                self:initGameView()
                self:refreshGameView()
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
            self.settings:saveSetting(self.settings_keys.puzzles_dir, ("%s/"):format(path))
            self.settings:flush()
        end
    }:chooseDir()
    self:lazyInitialization()
end

function Crossword:loadPuzzle()
    local file_path = ("%s/%s"):format(self.puzzle_dir, "/1990/01/01.json")
    local file, err = io.open(file_path, "rb")

    if not file then
        return _("Could not load crossword")
    end

    local file_content = file:read("*all")
    file:close()

    local Puzzle = require("puzzle")
    local puzzle = Puzzle:new{}
    puzzle:init(json.decode(file_content))
    return puzzle
end

function Crossword:initGameView()
    self.active_puzzle = self:loadPuzzle()
    self.ActiveGridView = GridView:new{
        size = {
            cols = self.active_puzzle.size.cols,
            rows = self.active_puzzle.size.rows
        },
        grid = self.active_puzzle:getGrid(),
        active_clue = "hint",
        on_tap_callback = function(row_num, col_num)
            -- On tap, pass the row and col nums to the active puzzle and return
            -- a clue based on the active direction (i.e.: across or down)
            -- Then update the grid (@todo: display touch feedback) and the clue in
            -- the active grid view. Then refresh this view.
            local clue = self.active_puzzle:getClueByPos(row_num, col_num, Solve.DOWN)
            if not clue then
                return false
            end
            self.ActiveGridView:updateGrid(self.active_puzzle:getGrid(), clue)
            self:refreshGameView()
        end
    }
end

function Crossword:refreshGameView()
    UIManager:show(self.ActiveGridView)
    self.ActiveGridView:render()
end

return Crossword
