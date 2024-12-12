local utils = require("user.utils")
local map = utils.map

M = {}

local started = false
local stack_left, stack_right, main_win_id = nil, nil, nil
local stack_size = 2

vim.api.nvim_create_user_command("TwmStart", function()
    require("user.commands.twm").start()
end, {})

vim.api.nvim_create_user_command("TwmPromote", function()
    if not started then
        vim.cmd("TwmStart")
    else
        pcall(require("user.commands.twm").promote)
    end
end, {})

vim.api.nvim_create_user_command("TwmFindFile", function()
    require("telescope.builtin").find_files({
        prompt_title = "Find File",
        attach_mappings = function(prompt_bufnr, map)
            local open_selected_file = function()
                local selection = require("telescope.actions.state").get_selected_entry()
                require("telescope.actions").close(prompt_bufnr)

                if selection then
                    local path = selection.path
                    local main_buf = vim.api.nvim_win_get_buf(main_win_id)
                    if vim.api.nvim_buf_get_name(main_buf) == path then
                        vim.api.nvim_set_current_win(main_win_id)
                        return
                    end

                    -- try to find the file on the stack first
                    local search_stack = function(stack, file_path)
                        for _, win in ipairs(stack) do
                            local buf = vim.api.nvim_win_get_buf(win)
                            if vim.api.nvim_buf_get_name(buf) == file_path then
                                return win
                            end
                        end

                        return nil
                    end

                    for _, stack in ipairs({ stack_left, stack_right }) do
                        local win = search_stack(stack, path)
                        if win ~= nil then
                            promote_stack_window(stack, win)
                            set_stack_size()
                            return
                        end
                    end

                    -- create new window, on stack, swap main and new, assign the path to new
                    local create_new_win_on_stack = function(stack, file_path)
                        vim.api.nvim_set_current_win(stack[1])
                        vim.cmd("sp | e " .. file_path)
                        local new_win = vim.api.nvim_get_current_win()
                        table.insert(stack, 2, new_win)
                        move_stack_window_to_top(stack, 2, new_win)
                        promote_stack_window(stack, new_win)
                    end

                    if #stack_left < #stack_right then
                        create_new_win_on_stack(stack_left, path)
                    else
                        create_new_win_on_stack(stack_right, path)
                    end

                    for _, stack in ipairs({ stack_left, stack_right }) do
                        clean_stack(stack)
                    end

                    set_stack_size()
                end
            end

            map("i", "<CR>", open_selected_file)
            map("n", "<CR>", open_selected_file)

            return true
        end,
    })
end, {})

map("n", "<leader>tw", Cmd("TwmStart"))
map("n", "<leader>.", Cmd("TwmPromote"))
map("n", "<leader>tf", Cmd("TwmFindFile"))
