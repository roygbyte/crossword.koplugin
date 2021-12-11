local logger = require("logger")

local Puzzle = {
    json_object = nil,
    size = {
        cols = nil,
        rows = nil,
    },
    grid = nil,
}

function Puzzle:new(o)
    o = o or {}   -- create object if user does not provide one
    setmetatable(o, self)
    self.__index = self
    return o
end

function Puzzle:init(json_object)
    -- Lazy error checking
    if not json_object then
        logger.dbg("Puzzle: json_object must be set for puzzle to be created.")
        return false
    end
    -- Onto the initialization
    self.size = json_object.size
    self.grid = {}
    local row = {} -- Start with an empty row to collect squares.
    for i, letter in ipairs(json_object.grid) do
        local grid_num = json_object.gridnums[i]
        -- Add a square to the row
        table.insert(row, {
                letter = letter and
                    letter or
                    "",
                number = grid_num ~= 0 and
                    tostring(grid_num) or
                    "",
        })
        -- Check whether to insert the row and reset the count.
        if i % self.size.cols == 0 then
            table.insert(self.grid, row)
            row = {} -- Empty the row table to collect the new set of squares.
        end
    end
end

function Puzzle:getGrid()
    return self.grid
end

function Puzzle:getSquareAtPos(row, col)
    return self.grid[row][col]
end

return Puzzle
