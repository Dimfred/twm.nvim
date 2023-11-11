local Stack = require("twm.stack")

local DoubleStackLayout = {}
DoubleStackLayout.__index = DoubleStackLayout

local default_opts = {
    left_stack = {
        size = 2,
        width = 80,
    },
    right_stack = {
        size = 2,
        width = 80,
    },
}

function DoubleStackLayout.new(opts)
    local self = setmetatable({}, DoubleStackLayout)

    self.stack_left = nil
    self.stack_right = nil
    self.main = nil

    self.opts = opts or default_opts

    if opts.filter == nil then
        opts.filter = function(window_id)
            local window_opts = vim.wo[window_id]
            local is_noice = window_opts.winhl:find("Noice")
            local is_telescope = window_opts.winhl:find("Telescope")

            local include_window = not is_noice and not is_telescope

            return include_window
        end
    end

    return self
end

function DoubleStackLayout:init(opts)
    self.main = vim.api.nvim_get_current_win()

    local current_tab = vim.api.nvim_get_current_tabpage()

    -- assing the windows to the left and right stack
    local stack_left, stack_right = {}, {}
    local stack = stack_left
    for _, window_id in ipairs(vim.api.nvim_list_wins()) do
        if
            window_id ~= self.main
            and current_tab == vim.api.nvim_win_get_tabpage(window_id)
            and vim.api.nvim_win_is_valid(window_id)
            and self.opts.filter(window_id)
        then
            if stack == stack_left then
                table.insert(stack_left, window_id)
                stack = stack_right
            else
                table.insert(stack_right, window_id)
                stack = stack_left
            end
        end
    end

    -- create stacks
    self.stack_left = Stack.new(stack_left, self.opts.left_stack.width, "far_left", self.opts.left_stack.size)
    self.stack_right = Stack.new(stack_right, self.opts.right_stack.width, "far_right", self.opts.right_stack.size)
    self:set_width()

    vim.api.nvim_set_current_win(self.main)
    vim.api.nvim_feedkeys("zz", "n", false)
end

function DoubleStackLayout:promote()
    if not self.opts.filter(vim.api.nvim_get_current_win()) then
        return
    end

    local new_main_id = self.stack_left:swap(self.main)
    if new_main_id ~= nil then
        self.main = new_main_id
    end

    new_main_id = self.stack_right:swap(self.main)
    if new_main_id ~= nil then
        self.main = new_main_id
    end

    self:set_width()
    vim.api.nvim_set_current_win(self.main)
end

function DoubleStackLayout:set_width()
    self.stack_left:set_width()
    self.stack_right:set_width()
end

function DoubleStackLayout:on_new_file(path)
    -- the new path is open in the main window
    local main_buf = vim.api.nvim_win_get_buf(self.main)
    if path == vim.api.nvim_buf_get_name(main_buf) then
        vim.api.nvim_set_current_win(self.main)
        return
    end

    -- try to find the path on the stack
    for _, stack in ipairs({ self.stack_left, self.stack_right }) do
        local win = stack:find_path(path)
        if win ~= nil then
            local new_main_id = stack:swap(self.main, win)
            if new_main_id ~= nil then
                self.main = new_main_id
                self:set_width()
                vim.api.nvim_set_current_win(self.main)
                return
            end
        end
    end

    local new_main_id = nil
    -- the new path is not open yet
    if #self.stack_left.stack <= #self.stack_right.stack then
        self.stack_left:new_win(path)
        new_main_id = self.stack_left:swap(self.main)
    else
        self.stack_right:new_win(path)
        new_main_id = self.stack_right:swap(self.main)
    end

    self:set_width()
    self.main = new_main_id
    vim.api.nvim_set_current_win(self.main)
end

return DoubleStackLayout
