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

local Crossword = WidgetContainer:new{
    name = "crossword",
    settings = nil,
    settings_keys = {
        puzzles_dir = "puzzles_dir"
    },
    puzzles_dir = nil,
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
                self:gameView()
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

function Crossword:gameView()
    local file_path = ("%s/%s"):format(self.puzzle_dir, "/1990/01/01.json")
    local file, err = io.open(file_path, "rb")

    if not file then
        return _("Could not load crossword")
    end

    local file_content = file:read("*all")
    file:close()

    local puzzle = json.decode(file_content)
    logger.dbg(puzzle)
    -- Create the grid, which contains the letters for
    -- each row.
    local grid = {}
    local row = {}
    for i, letter in ipairs(puzzle.grid) do
        table.insert(row, {
                letter = letter,
                number = puzzle.gridnums[i],
        })
        if i % 15 == 0 then
            table.insert(grid, row)
            row = {}
        end
    end

    local PuzzleView = require("puzzleview")
    PuzzleView = PuzzleView:new{
        size = {
            cols = puzzle.size.cols,
            rows = puzzle.size.rows
        },
        grid = grid
    }

    UIManager:show(PuzzleView)
end

return Crossword
