local KeyValuePage = require("ui/widget/keyvaluepage")
local UIManager = require("ui/uimanager")

local util = require("util")
local lfs = require("libs/libkoreader-lfs")
local logger = require("logger")
local sort = require("frontend/sort")

local Puzzle = require("puzzle")

local function titleToMonth(title)
    local months = {
        ["01"] = "January",
        ["02"] = "February",
        ["03"] = "March",
        ["04"] = "April",
        ["05"] = "May",
        ["06"] = "June",
        ["07"] = "July",
        ["08"] = "August",
        ["09"] = "September",
        ["10"] = "October",
        ["11"] = "November",
        ["12"] = "December",
    }
    return months[title] or title
end

local Library = {
   puzzle_dir = nil,
   onSelectPuzzle = function() end
}

function Library:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

--[[--
Given a directory, return a table of files located within this directory. Filter
the files by type and extension, showing only JSON files. These are assumed to be
the crossword puzzles.
]]
function Library:getFilesInDirectory(path_to_dir)
   local items = {}

   local ok, iter, dir_obj = pcall(lfs.dir, path_to_dir)
   if not ok then
      return items
   end

   for f in iter, dir_obj do
      local attributes = lfs.attributes(("%s/%s"):format(path_to_dir, f))
      if attributes.mode == "directory"
         or attributes.mode == "file"
         and f ~= "."
         and f ~= ".."
         and util.stringEndsWith(f, ".json")
      then
         local title = (attributes.mode == "directory") and
            f or -- Use the file name as the title
            Puzzle:initializePuzzle(("%s/%s"):format(path_to_dir, f)).title -- Use the puzzle's name as the title
         local item = {
            title = title, -- The item's name to show the user.
            filename = f, -- The item's name in the filesystem.
            mode = attributes.mode, -- The mode of the item  (i.e.: file or directory).
            path_to_dir = path_to_dir -- The path to the item's directory.
         }
         -- Maybe change the title into a month
         item.title = titleToMonth(item.title)
         table.insert(items, item)
      end
   end

   table.sort(items, function(a, b)
          local fn = sort.natsort_cmp()
          return fn(a.filename, b.filename)
   end)

   return items
end

function Library:processDirectoryCallback(item)
   if item.mode == "directory" then
      self:showDirectoryView(("%s/%s"):format(item.path_to_dir, item.filename))
   else
      self.onSelectPuzzle(item)
   end
end

function Library:showDirectoryView(path_to_directory)
   local directory_items = self:getFilesInDirectory(path_to_directory)
   local kv_pairs = {}
   for key, item in ipairs(directory_items) do
      table.insert(kv_pairs, {
            item.title,
            "",
            callback = function()
               self:processDirectoryCallback(item)
            end
      })
   end
   UIManager:show(KeyValuePage:new{
         title = "Puzzles",
         kv_pairs = kv_pairs
   })
end

return Library
