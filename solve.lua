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
    if direction == Solve.DOWN then
        local word_length = string.len(self.word)
        for position = 0, word_length, 1 do
            local start_row = self.grid_num / width
            table.insert(grid_indices, grid_index)
        end
    elseif direction == Solve.ACROSS then

    end
end

return Solve
