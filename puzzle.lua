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
    -- Cycle through each of the 'solves' and add each element to a list
    -- called 'squares' which will eventually be passed to the view.
    local grid = {}
    for solve_index, solve in ipairs(self.solves) do
        -- Each solve contains indices that point to the other squares where its letters
        -- are contained. Loop through the indices and build a square element.
        for i, grid_index in ipairs(solve.grid_indices) do
            -- Check to see if a number should be set for this grid square
            local number = tonumber(grid_index) == tonumber(solve.grid_num) and
                solve.clue_num or
                ""
            -- Check to see if the squares contains an entry for the given
            -- grid index. Positions in the table are used to indicate the index.
            -- So, something at squares[4] is the 4th square in the puzzle view, and should
            -- include an index to the solve it is for.
            if not grid[grid_index] then
                -- Make the initial element and add it to the list.
                local grid_square = {
                    solve_indices = {solve_index},
                    letter = string.sub(solve.word, i, i), -- Get first character of word,
                    number = number
                }
                grid[grid_index] = grid_square
            else
                -- Since the square has been initialized, update the existing element.
                table.insert(grid[grid_index].solve_indices, solve_index)
                -- Set the number if it is not null. This is necessary to account for the
                -- fact that the first direction processed will have already initialized
                -- all of the squares.
                if number ~= "" then
                    grid[grid_index].number = number
                end
            end
        end
    end
    -- Now, go through the squares and add empty squares to fill in the gaps.
    -- We use the size of the grid as the limit, because that will cover
    -- numbers that haven't been assigned values in the list.
    for i = 1, (self.size.cols * self.size.rows), 1 do
        if not grid[i] then
            grid[i] = {
                letter = ".",
                number = "",
            }
        end
    end
    -- Now, go through the grid and turn it into a legit grid, so that the structure
    -- resembles something like this:
    -- [1] = {
    --    [1] = {
    --        ["number"] = "1",
    --        ["letter"] = "A",
    --        ...
    local temp_grid = {}
    local row = {}
    for i, grid_square in ipairs(grid) do
        table.insert(row, grid_square)
        if i % self.size.cols == 0 then
            table.insert(temp_grid, row)
            row = {}
        end
    end
    -- Update the object's value for self.grid, in case its accessed elsewhere.
    -- And obviously return the grid.
    self.grid = temp_grid
    return self.grid
end

function Puzzle:setActiveSquare(row, col)
    self.active_square_index = ((row - 1) * self.size.rows) + col
end

function Puzzle:getSquareAtPos(row, col)
    local index = ((row - 1) * self.size.rows) + col
    return self.solves[index]
end

function Puzzle:getSolveByIndex(index)
    return self.solves[index]
end

function Puzzle:getClueByPos(row, col, direction)
    local clue
    local grid_elm = self.grid[row][col]
    if not grid_elm or not grid_elm.solve_indices then
        return nil
    end
    for i, solve_index in ipairs(grid_elm.solve_indices) do
        local solve = self.solves[solve_index]
        if not clue and solve.direction == direction then
            clue = solve.clue
        end
    end
    return clue
end

return Puzzle
