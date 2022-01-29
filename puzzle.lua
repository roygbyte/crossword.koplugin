local md5 = require("ffi/sha2").md5
local logger = require("logger")

local Guess = require("guess")
local Solve = require("solve")
local State = require("state")

local Puzzle = State:new{
    size = {
        cols = nil,
        rows = nil,
    },
    grid = nil,
    active_direction = nil,
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
    -- Initialize the player's inputs.
    self.guesses = {}
    -- Initialize the puzzle's title, etc.
    self.title = json_object.title
    self.editor = json_object.editor
    self.id = md5(json_object.title)
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
        -- Check to see if active_square_index is contained within the grid indices AND
        -- the solve's direction matches the active direction. If both conditions are true,
        -- we should highlight the squares for the row or column area.
        local row_state = nil
        if solve.direction == self.active_direction then
            for i, grid_index in ipairs(solve.grid_indices) do
                if tonumber(self.active_square_index) == tonumber(grid_index) then
                    row_state = "1"
                end
            end
        end
        -- Each solve contains indices that point to the other squares where its letters
        -- are contained. Loop through the indices and build a square element.
        for i, grid_index in ipairs(solve.grid_indices) do
            -- Check to see if a number should be set for this grid square
            local number = tonumber(grid_index) == tonumber(solve.grid_num) and
                solve.clue_num or
                ""
            -- Set the letter, or not.
            local letter = self:getLetterForSquare(grid_index)
            -- Check to see if the grid element should be set to selected.
            local state = tonumber(grid_index) == self.active_square_index and
                "2" or
                row_state
            local status = self:getStatusForSquare(grid_index)
            -- Check to see if the squares contains an entry for the given
            -- grid index. Positions in the table are used to indicate the index.
            -- So, something at squares[4] is the 4th square in the puzzle view, and should
            -- include an index to the solve it is for.
            if not grid[grid_index] then
                -- Make the initial element and add it to the list. Some attributes are only
                -- set once (like the letter).
                local grid_square = {
                    solve_indices = { solve_index },
                    number = number,
                    letter = letter,
                }
                grid[grid_index] = grid_square
            else
                -- Since the square has been initialized, update the existing element.
                table.insert(grid[grid_index].solve_indices, solve_index)
            end
            -- Update the number, but only if it is not an empty value. Otherwise the down number will
            -- overwrite the across numbers.
            if number ~= "" then
                grid[grid_index].number = number
            end
            -- Updating state like this could overwrite a state value that was set by the
            -- other direction of squares. So there needs to be a kind of conditional statement
            -- that checks to see if state has a value.
            if not grid[grid_index].state then
                grid[grid_index].state = state
            end
            if not grid[grid_index].status then
                grid[grid_index].status = status
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

function Puzzle:getActiveSquare()
    return self.active_square_index
end

function Puzzle:resetActiveSquare()
    self.active_square_index = -1
end

function Puzzle:getSquareAtPos(row, col)
    local index = ((row - 1) * self.size.rows) + col
    return self.solves[index]
end

function Puzzle:getNextIndexForDirection(index, direction)
    index = index + 1
    local solve = self.solves[index]
    -- If solve is nil, we're probably at the end of the list,
    -- so call this method again from start of list (but we call the
    -- method with '0' because the function will advance the index to 1.
    if solve == nil then
        return self:getNextIndexForDirection(0, direction)
    end
    -- If solve direction does not match desired direction, advance
    -- the index and call this method again.
    if solve.direction ~= direction then
        return self:getNextIndexForDirection(index, direction)
    end
    -- If we made it this far then we have the next solve.
    return solve
end

function Puzzle:getPrevIndexForDirection(index, direction)
    index = index - 1
    local solve = self.solves[index]
    -- See sister method for explanation of logic.
    if solve == nil then
        return self:getPrevIndexForDirection(#self.solves, direction)
    end
    if solve.direction ~= direction then
        return self:getPrevIndexForDirection(index, direction)
    end
    return solve
end

function Puzzle:getSolveByIndex(index)
    return self.solves[index]
end

function Puzzle:setLetterForGuess(letter, grid_elm)
    if not self.guesses[grid_elm] then
        self.guesses[grid_elm] = {}
    end
    -- If the incoming letter is different than the letter already set,
    -- then the status of the guess can be reset.
    if self.guesses[grid_elm].letter then
        if self.guesses[grid_elm].letter ~= letter then
            self.guesses[grid_elm].status = Guess.STATUS.UNCHECKED
        end
    end
    self.guesses[grid_elm].letter = letter
end

function Puzzle:getLetterForSquare(grid_elm)
    if not self.guesses[grid_elm] then
        return ""
    else
        return self.guesses[grid_elm].letter or ""
    end
end

function Puzzle:getStatusForSquare(grid_elm)
    if not self.guesses[grid_elm] then
        return nil
    else
        return self.guesses[grid_elm].status
    end
end

function Puzzle:setActiveDirection(direction)
    self.active_direction = direction
end

-- Given a grid position (row, col) and direction (across or down), find another grid
-- position that corresponds to the next clue.
function Puzzle:getNextCluePos(row, col, direction)
    local _, index = self:getSolveByPos(row, col, direction)
    local next_solve = self:getNextIndexForDirection(index, direction)
    local next_position = next_solve.grid_num
    local next_row = math.ceil(next_position / self.size.rows)
    local next_col = self.size.cols - ((next_row * self.size.rows) - next_position)
    return next_row, next_col
end

-- Given a grid position (row, col) and direction (across or down), find another grid
-- position that corresponds to the next clue.
function Puzzle:getPrevCluePos(row, col, direction)
    local _, index = self:getSolveByPos(row, col, direction)
    local prev_solve = self:getPrevIndexForDirection(index, direction)
    local prev_position = prev_solve.grid_num
    local prev_row = math.ceil(prev_position / self.size.rows)
    local prev_col = self.size.cols - ((prev_row * self.size.rows) - prev_position)
    return prev_row, prev_col
end

function Puzzle:getSolveByPos(row, col, direction)
    local solve
    local index
    local grid_elm = self.grid[row][col]
    if not grid_elm or not grid_elm.solve_indices then
        return nil
    end
    for i, solve_index in ipairs(grid_elm.solve_indices) do
        local temp_solve = self.solves[solve_index]
        if not solve and temp_solve.direction == direction then
            index = solve_index
            solve = temp_solve
        end
    end
    return solve, index
end

function Puzzle:getClueByPos(row, col, direction)
    local solve = self:getSolveByPos(row, col, direction)
    if not solve then
        return nil
    end
    return solve.clue
end

function Puzzle:isSquareCorrect(square)
    local guess = self:getLetterForSquare(square)

    for i, solve in ipairs(self.solves) do
        for k, grid_index in ipairs(solve.grid_indices) do
            if square == grid_index then
                -- get the word character at index k and compare with guess.
                local char = string.sub(solve.word, k, 1)
                if char == guess then
                    return true
                end
            end
        end
    end
    return false
end

function Puzzle:checkPuzzle()
    local grid_elm_results = {}
    for i, solve in ipairs(self.solves) do
        for char_pos, grid_index in ipairs(solve.grid_indices) do
            if self.guesses[grid_index] and not grid_elm_results[grid_index] then
                logger.dbg("Checking " .. grid_index)
                local letter_guess = self.guesses[grid_index].letter
                local letter_solve = string.sub(solve.word, char_pos, 1)
                local guess_status = (letter_guess == letter_solve) and
                    Guess.STATUS.CHECKED_CORRECT or
                    Guess.STATUS.CHECKED_INCORRECT
                grid_elm_results[grid_index] = guess_status
            else
                logger.dbg("Skipping: Already checked or no guess found " .. grid_index)
            end
        end
    end
    for grid_elm, status in pairs(grid_elm_results) do
        if self.guesses[grid_elm] then
            self.guesses[grid_elm].status = status
        end
    end
    logger.dbg(self.guesses)
end

return Puzzle
