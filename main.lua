--[[--
This is a debug plugin to test Plugin functionality.

@module koplugin.HelloWorld
--]]--

-- This is a debug plugin, remove the following if block to enable it

local Dispatcher = require("dispatcher")  -- luacheck:ignore
local InfoMessage = require("ui/widget/infomessage")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

local Crossword = WidgetContainer:new{
    name = "crossword",
}

function Crossword:init()
    self.ui.menu:registerToMainMenu(self)
end

function Crossword:addToMainMenu(menu_items)
    menu_items.crossword = {
        text = _("Crossword"),
        -- a callback when tapping
        sorting_hint = "tools",
        callback = function()
            self:gameView();
        end,
    }
end

function Crossword:gameView()
    local Puzzle = require("puzzle"):new{}
    UIManager:show(Puzzle)
end

return Crossword
