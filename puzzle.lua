local logger = require("logger")
local Solve = require("solve")

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
    -- Onto the initialization.
    self.size = json_object.size
    -- Initialize the solves.
    self.solves = {}
    -- Create the down and across solves.
    self:createSolves(json_object.clues.down, json_object.answers.down, Solve.DOWN, json_object.gridnums)
    self:createSolves(json_object.clues.across, json_object.answers.across, Solve.ACROSS, json_object.gridnums)
    -- Temp grid construction, to be replaced by Puzzle:getGrid
    -- Below: works!
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
-- For lack of better naming, the "solves" are the combination of
-- word, direction, and clue that make up a crossword puzzle. This method
-- creates the solves from a four separate lists. That fours lists are
-- needed to do this really is just an accomodation for the data source,
-- i.e.: the NYT crossword archives. Theoretically, if we were using a different
-- data source we might want to make another method for creating the solves because,
-- really, the object doesn't care where the data is coming from. It just wants
-- the data. Nom, nom, nom!
function Puzzle:createSolves(clues, answers, direction, grid_nums)
    for i, clue in ipairs(clues) do
        local solve = Solve:new{
            word = answers[i],
            direction = direction,
            clue = clue,
        }
        -- Some values are easiest initialized within the object.
        solve:init(self.size, grid_nums)
        table.insert(self.solves, solve)
    end
end
-- For now, we build the grid from scratch everytime we access it.
function Puzzle:getGrid()
    -- Below: temp! Not working!! All buggered up!!
    -- We want to be able to build a grid only from our "Solve" objects,
    -- and not the cheater gridnums list in the NYT archives data source.
    local grid = {}
    for solve_index, solve in ipairs(self.solves) do
        -- Within solve.indices are all of the grid_index numbers
        -- for which we will want to assign this solve. One single grid element may
        -- point to multiple (at most two) solves.
        logger.dbg(solve.grid_indices)
        for i, grid_index in ipairs(solve.grid_indices) do
            -- Check to see if the grid table contains an entry for the given
            -- grid index. Positions in the table are used to indicate the index.
            -- So, something at grid[4] is the 4th square in the puzzle view, and should
            -- include an index to the solve it is for.
            if not grid[grid_index] then
                -- Make the initial element and add it to the list.
                local grid_elm = {
                    solve_indices = {solve_index},
                    letter = string.sub(solve.word, i, i + 1), -- Get first character of word,
                    number = solve.clue_num,
                }
                grid[grid_index] = grid_elm
            else
                -- Update the existing element
                table.insert(grid[grid_index].solve_indices, solve_index)
            end
        end
    end
    logger.dbg(grid)
end

function Puzzle:getSquareAtPos(row, col)
    local index = ((row - 1) * self.size.rows) + col
    logger.dbg(index)
    return self.solves[index]
end

return Puzzle
