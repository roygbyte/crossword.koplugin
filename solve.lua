local logger = require("logger")

local Solve = {
   word = nil,
   direction = nil,
   start = nil,
   clue = nil,
   clue_num = nil,
   grid_num = nil,
   grid_indices = nil,
}

Solve.ACROSS = "across"
Solve.DOWN = "down"

function Solve:new(o)
   o = o or {}
   setmetatable(o, self)
   self.__index = self
   return o
end

function Solve:init(puzzle_size, puzzle_grid_nums)
   -- Compute the clue num.
   for token in string.gmatch(self.clue, "[^.]*") do
      if not self.clue_num then
         self.clue_num = token
      end
   end
   -- Computer the grid num.
   for grid_num, clue_num in ipairs(puzzle_grid_nums) do
      if tonumber(self.clue_num) == tonumber(clue_num) then
         self.grid_num = grid_num
      end
   end
   -- Compute the grid indices. I.e.: each index on the grid that
   -- is occupied by one of this solve's letters.
   self.grid_indices = {}
   local word_length = string.len(self.word)
   local width = puzzle_size.cols
   local height = puzzle_size.rows
   --local start_row = math.ceil(self.grid_num / height)
   --local start_col = puzzle_size.cols - ((start_row * width) - self.grid_num)

   if self.direction == Solve.DOWN then
      local index = 0
      for char in string.gmatch(self.word, "[A-Z]") do
         local grid_index = self.grid_num + (index * width)
         table.insert(self.grid_indices, grid_index)
         index = index + 1
      end
   elseif self.direction == Solve.ACROSS then
      local index = 0
      for char in string.gmatch(self.word, "[A-Z]") do
         local grid_index = self.grid_num + index
         table.insert(self.grid_indices, grid_index)
         index = index + 1
      end
   end
end

return Solve
