local utils = require("twm.utils")

local Stack = {}
Stack.__index = Stack

--------------------------------------------------------------------------------
-- PUBLIC
function Stack.new(window_ids, width, dir, stack_size)
    local self = setmetatable({}, Stack)
    self.width = width
    self.stack_size = stack_size

    if #window_ids >= 1 then
        self.stack = window_ids
    else
        self.stack = self:_init_empty()
    end
    self:_init(dir)

    self:clean()

    return self
end

function Stack:new_win(path)
    vim.api.nvim_set_current_win(self.stack[1])

    vim.cmd("sp | e " .. path)
    local new_win = vim.api.nvim_get_current_win()
    table.insert(self.stack, 2, new_win)
    self:_window_to_top(new_win)

    self:clean()

    return new_win
end

function Stack:swap(window_id, stack_window_id)
    if stack_window_id == nil then
        stack_window_id = vim.api.nvim_get_current_win()
    end

    local ok = self:_window_to_top(stack_window_id)
    if not ok then
        return nil
    end

    self:_swap_top(window_id)

    return stack_window_id
end

function Stack:clean()
    for idx, win in ipairs(self.stack) do
        local buf = vim.api.nvim_win_get_buf(win)
        local name = vim.api.nvim_buf_get_name(buf)

        -- removes the empty place holder buffer, if we have at least one window there
        if name == "" and #self.stack > 1 then
            vim.api.nvim_win_close(win, true)
            table.remove(self.stack, idx)
        end

        -- if the stack is bigger than the allowed size, remove the last recently
        -- used window
        if #self.stack > self.stack_size then
            vim.api.nvim_win_close(self.stack[self.stack_size + 1], true)
            table.remove(self.stack, self.stack_size + 1)
        end
    end

    self:set_width()
end

function Stack:set_width()
    vim.api.nvim_win_set_width(self.stack[1], self.width)
end

function Stack:find_path(path)
    for _, stack_win in ipairs(self.stack) do
        local buf = vim.api.nvim_win_get_buf(stack_win)
        if path == vim.api.nvim_buf_get_name(buf) then
            return stack_win
        end
    end

    return nil
end

function Stack:_window_to_top(window_id)
    local stack_idx = self:_find_window(window_id)
    -- the window is not part of the stack
    if stack_idx == nil then
        return false
    end

    -- the window is already on top
    if stack_idx == 1 then
        return true
    end

    -- swap the windows, and the stack indeces
    utils.col_move_in(window_id, self.stack[1])
    self.stack[stack_idx] = self.stack[1]
    self.stack[1] = window_id

    return true
end

function Stack:_swap_top(window_id)
    utils.swap_windows(window_id, self.stack[1])

    local current_stack_win_id = self.stack[1]
    self.stack[1] = window_id

    return current_stack_win_id
end

function Stack:_find_window(window_id)
    for idx, stack_win in ipairs(self.stack) do
        if stack_win == window_id then
            return idx
        end
    end

    return nil
end

function Stack:_init(dir)
    -- move the top stack window onto it's position
    vim.api.nvim_set_current_win(self.stack[1])
    utils.move_win(self.stack[1], dir)

    -- move all windows below the top stack window
    for i = 2, #self.stack do
        utils.col_move_in(self.stack[i], self.stack[1], "down")
    end
end

function Stack:_init_empty()
    local buf = vim.api.nvim_create_buf(true, false)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "win",
        width = self.width,
        height = vim.o.columns,
        row = 0,
        col = 0,
    })

    return { win }
end

return Stack
