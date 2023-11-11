local M = {}

M.swap_windows = function(a, b)
    local winshift = require("winshift.lib")

    local tree = winshift.get_layout_tree()
    local leaf_a = winshift.find_leaf(tree, a)
    local leaf_b = winshift.find_leaf(tree, b)
    winshift.swap_leaves(leaf_a, leaf_b)
end

M.col_move_in = function(a, b, dir)
    local winshift = require("winshift.lib")

    local tree = winshift.get_layout_tree()
    local leaf_a = winshift.find_leaf(tree, a)
    local leaf_b = winshift.find_leaf(tree, b)
    if leaf_a and leaf_b then
        winshift.col_move_in(leaf_a, leaf_b, dir)
    end
end

M.move_win = function(window_id, dir)
    local winshift = require("winshift.lib")
    winshift.move_win(window_id, dir)
end

return M
