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
local KeyValuePage = require("ui/widget/keyvaluepage")
local LuaSettings = require("frontend/luasettings")
local logger = require("logger")
local lfs = require("libs/libkoreader-lfs")
local json = require("json")
local util = require("util")
local _ = require("gettext")

local Solve = require("solve")
local GridView = require("gridview")
local GridInput = require("gridinput")
local GameView = require("gameview")

local Crossword = WidgetContainer:new{
    name = "crossword",
    settings = nil,
    settings_keys = {
        puzzle_library_dir = "puzzle_library_dir"
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
            text = _("Continue last puzzle"),
            callback = function()
                --- @todo: fetch last puzzle
                self:showGameView()
                --self:initGameView()
                --self:refreshGameView()
            end
        },
        {
            text = _("Puzzle Library"),
            callback = function()
                self:showLibraryDirectory(self.puzzle_dir)
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
            self.settings:saveSetting(self.settings_keys.puzzle_library_dir, ("%s/"):format(path))
            self.settings:flush()
        end
    }:chooseDir()
    self:lazyInitialization()
end

function Crossword:showGameView(puzzle)
    local game_view = GameView:new{
        puzzle = puzzle
    }
    game_view:render()
    UIManager:show(game_view)
end

function Crossword:loadPuzzle(path_to_file)
    local file, err = io.open(path_to_file, "rb")

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

function Crossword:getFilesInDirectory(path_to_dir)
    local items = {}

    local ok, iter, dir_obj = pcall(lfs.dir, path_to_dir)
    if not ok then
        return items
    end

    for f in iter,  dir_obj do
        local attributes = lfs.attributes(("%s/%s"):format(path_to_dir, f))
        if attributes.mode == "directory"
            or attributes.mode == "file"
            and f ~= "."
            and f ~= ".."
            and util.stringEndsWith(f, ".json")
        then
            local item = {
                filename = f,
                mode = attributes.mode,
                path_to_dir = path_to_dir
            }
            table.insert(items, item)
        end
    end

    return items
end

function Crossword:processDirectoryItem(item)
    local path_to_file = ("%s/%s"):format(item.path_to_dir, item.filename)
    if item.mode == "directory" then
        self:showLibraryDirectory(path_to_file)
    else
        local puzzle = self:loadPuzzle(path_to_file)
        self:showGameView(puzzle)
    end
end
-- This is an awful name for this method signature. We are not loading anything...
function Crossword:showLibraryDirectory(path_to_directory)
    -- Get the directory items.
    local directory_items = self:getFilesInDirectory(path_to_directory)
    -- Build the kv pairs to send to the view.
    local kv_pairs = {}
    for key, value in ipairs(directory_items) do
        -- Set default title to the filename. If the file is a directory, this value won't change.
        local title = value.filename
        -- Otherwise, set the title to the puzzle's title.
        if value.mode == "file" then
            local path_to_puzzle = ("%s/%s"):format(value.path_to_dir, value.filename)
            local puzzle = self:loadPuzzle(path_to_puzzle)
            --- @todo: Check if loaded puzzle is valid.
            --- @todo: Check if loaded puzzle exists in an in-progress state.
            title = puzzle.title
        end
        local pair = {
            title,
            "",
            callback = function()
                self:processDirectoryItem(value)
            end
        }
        table.insert(kv_pairs, pair)
    end
    UIManager:show(KeyValuePage:new{
        title = "Puzzles",
        kv_pairs = kv_pairs
    })
end

return Crossword
