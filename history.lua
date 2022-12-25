local DataStorage = require("datastorage")
local LuaSettings = require("frontend/luasettings")
local logger = require("logger")

local History = {
   history_file = "crossword_history.lua",
   lua_settings = nil,
}

History.STACK = "stack"
History.MAX_ITEMS = 100

function History:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   o:init()
   return o
end

function History:init()
   self.lua_settings = LuaSettings:open(("%s/%s"):format(DataStorage:getSettingsDir(), self.history_file))
end

--[[

]]
function History:add(puzzle_id, puzzle_title)
   -- Add to the history by pushing to the first element of the list.
   -- The history stack should only contain one entry of a given ID.
   -- The list should only contain 10 entries.
   local stack = self.lua_settings:readSetting(History.STACK) or {}
   -- Add the new entry to the stack table.
   table.insert(stack, {
         puzzle_id = puzzle_id,
         puzzle_title = puzzle_title,
         timestamp = os.time(os.date("!*t"))
   })
   -- Sort the table by the timestamp key.
   table.sort(stack, function(a,b) return a.timestamp > b.timestamp end)
   -- Delete duplicate entries, given by puzzle id, by looping through
   -- the stack and keeping the first occurance (i.e.: newest) of
   -- a puzzle's history.
   local new_stack = {}
   local duplicates = {}
   local index = 1
   for i, value in ipairs(stack) do
      if duplicates[value.puzzle_id] == nil then
         duplicates[value.puzzle_id] = true
         table.insert(new_stack, value)
         index = index + 1
      end
      if index > History.MAX_ITEMS then
         break;
      end
   end
   -- Save 'er.
   self.lua_settings:saveSetting(History.STACK, new_stack)
   self.lua_settings:flush()
end

function History:get()
   local stack = self.lua_settings:readSetting(History.STACK) or {}
   return stack
end

function History:save()

end

function History:clear()
   self.lua_settings:saveSetting(History.STACK, {})
   self.lua_settings:flush()
end

return History
