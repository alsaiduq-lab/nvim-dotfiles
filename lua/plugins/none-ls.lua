return {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "mason.nvim",
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        local null_ls = require("null-ls")
        local methods = require("null-ls.methods")
        local CODE_ACTION = methods.internal.CODE_ACTION
        local sources = {}
        local advanced_transforms = {
            name = "advanced_code_transforms",
            method = CODE_ACTION,
            filetypes = { "javascript", "typescript", "lua", "python", "go", "rust", "c", "cpp", "java" },
            generator = {
                fn = function(params)
                    local actions = {}
                    local bufnr = params.bufnr
                    local filetype = params.ft
                    local function get_file_content()
                        return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
                    end
                    local row, col = params.range.row - 1, params.range.col
                    local parser_ok, parser = pcall(vim.treesitter.get_parser, bufnr, filetype)
                    if not parser_ok then
                        return actions
                    end
                    local tree = parser:parse()[1]
                    if not tree then
                        return actions
                    end
                    local root = tree:root()
                    if not root then
                        return actions
                    end
                    local node_ok, node = pcall(vim.treesitter.get_node, {
                        bufnr = bufnr,
                        pos = { row, col },
                    })
                    if not node_ok or not node then
                        return actions
                    end
                    if filetype == "javascript" or filetype == "typescript" then
                        if node:type() == "for_statement" or node:type() == "for_in_statement" then
                            local node_text_ok, loop_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                            if not node_text_ok then
                                return actions
                            end
                            if loop_text:match("for%s*%(.-;.-;.-%s*%)%s*{%s*[%w_]+%.push") then
                                table.insert(actions, {
                                    title = "Convert to Array.map()",
                                    action = function()
                                        local loop_body
                                        local child_ok, child = pcall(function()
                                            return node:child(3)
                                        end)
                                        if child_ok and child then
                                            loop_body = child
                                        else
                                            return
                                        end
                                        local body_text_ok, body_text =
                                            pcall(vim.treesitter.get_node_text, loop_body, bufnr)
                                        if not body_text_ok then
                                            return
                                        end
                                        local array_name = body_text:match("[%w_]+%.push")
                                        if array_name then
                                            array_name = array_name:sub(1, -6) -- remove .push
                                        end
                                        local iterator_ok, iterator = pcall(function()
                                            return node:child(0):child(1)
                                        end)
                                        local iterator_text
                                        if iterator_ok and iterator then
                                            local text_ok
                                            text_ok, iterator_text =
                                                pcall(vim.treesitter.get_node_text, iterator, bufnr)
                                            if not text_ok then
                                                iterator_text = "i"
                                            end
                                        else
                                            iterator_text = "i"
                                        end
                                        local value_expr = body_text:match("push%((.-)%)") or ""
                                        local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                            local sr, sc, er, ec = node:range()
                                            return sr, sc, er, ec
                                        end)
                                        if not range_ok then
                                            return
                                        end
                                        local replacement = array_name
                                            .. " = "
                                            .. array_name
                                            .. ".map(("
                                            .. iterator_text
                                            .. ", index) => {\n  return "
                                            .. value_expr
                                            .. ";\n});"
                                        pcall(
                                            vim.api.nvim_buf_set_text,
                                            bufnr,
                                            start_row,
                                            start_col,
                                            end_row,
                                            end_col,
                                            vim.split(replacement, "\n")
                                        )
                                    end,
                                })
                            end
                            if loop_text:match("for%s*%(.-;.-;.-%s*%)%s*{%s*if%s*%(.-%)%s*{%s*[%w_]+%.push") then
                                table.insert(actions, {
                                    title = "Convert to Array.filter()",
                                    action = function()
                                        local loop_body
                                        local child_ok, child = pcall(function()
                                            return node:child(3)
                                        end)
                                        if child_ok and child then
                                            loop_body = child
                                        else
                                            return
                                        end
                                        local body_text_ok, body_text =
                                            pcall(vim.treesitter.get_node_text, loop_body, bufnr)
                                        if not body_text_ok then
                                            return
                                        end
                                        local array_name = body_text:match("[%w_]+%.push")
                                        if array_name then
                                            array_name = array_name:sub(1, -6) -- remove .push
                                        end
                                        local condition = body_text:match("if%s*%((.-)%)") or ""
                                        local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                            local sr, sc, er, ec = node:range()
                                            return sr, sc, er, ec
                                        end)
                                        if not range_ok then
                                            return
                                        end
                                        local replacement = array_name
                                            .. " = "
                                            .. array_name
                                            .. ".filter(item => "
                                            .. condition
                                            .. ");"
                                        pcall(
                                            vim.api.nvim_buf_set_text,
                                            bufnr,
                                            start_row,
                                            start_col,
                                            end_row,
                                            end_col,
                                            vim.split(replacement, "\n")
                                        )
                                    end,
                                })
                            end
                        end
                    end
                    if filetype == "javascript" or filetype == "typescript" then
                        local node_text_ok, node_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                        if not node_text_ok then
                            return actions
                        end
                        if node:type() == "call_expression" and node_text:match("%(.-function%s*%(.-%)%s*{") then
                            table.insert(actions, {
                                title = "Convert callback to Promise",
                                action = function()
                                    local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                        local sr, sc, er, ec = node:range()
                                        return sr, sc, er, ec
                                    end)
                                    if not range_ok then
                                        return
                                    end
                                    local replacement = "new Promise((resolve, reject) => {\n"
                                        .. "  "
                                        .. node_text:gsub(
                                            "%(function%(",
                                            "(function(err, result) {\n"
                                                .. "    if (err) {\n"
                                                .. "      reject(err);\n"
                                                .. "      return;\n"
                                                .. "    }\n"
                                                .. "    resolve(result);\n  "
                                        )
                                        .. "\n})"
                                    pcall(
                                        vim.api.nvim_buf_set_text,
                                        bufnr,
                                        start_row,
                                        start_col,
                                        end_row,
                                        end_col,
                                        vim.split(replacement, "\n")
                                    )
                                end,
                            })
                            table.insert(actions, {
                                title = "Convert to async/await",
                                action = function()
                                    local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                        local sr, sc, er, ec = node:range()
                                        return sr, sc, er, ec
                                    end)
                                    if not range_ok then
                                        return
                                    end
                                    local callback_idx = node_text:find("function%s*%(")
                                    if callback_idx then
                                        local before_callback = node_text:sub(1, callback_idx - 1)
                                        local replacement = "await new Promise((resolve, reject) => {\n"
                                            .. "  "
                                            .. before_callback
                                            .. "function(err, result) {\n"
                                            .. "    if (err) {\n"
                                            .. "      reject(err);\n"
                                            .. "      return;\n"
                                            .. "    }\n"
                                            .. "    resolve(result);\n  });\n"
                                            .. "});"
                                        pcall(
                                            vim.api.nvim_buf_set_text,
                                            bufnr,
                                            start_row,
                                            start_col,
                                            end_row,
                                            end_col,
                                            vim.split(replacement, "\n")
                                        )
                                    end
                                end,
                            })
                        end
                    end
                    if
                        (filetype == "javascript" or filetype == "typescript")
                        and node:type() == "function_declaration"
                    then
                        local node_text_ok, func_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                        if not node_text_ok then
                            return actions
                        end
                        local func_name = func_text:match("function%s+([%w_]+)")
                        if func_name then
                            local content = get_file_content()
                            local related_funcs = {}
                            for other_func in content:gmatch("function%s+(" .. func_name .. "[%w_]*)") do
                                if other_func ~= func_name then
                                    table.insert(related_funcs, other_func)
                                end
                            end
                            if #related_funcs > 0 then
                                table.insert(actions, {
                                    title = "Extract class from related functions",
                                    action = function()
                                        local class_text = "class " .. func_name:gsub("^%l", string.upper) .. " {\n"
                                        local params = func_text:match("function%s+[%w_]+%s*%((.-)%)") or ""

                                        class_text = class_text .. "  constructor(" .. params .. ") {\n"
                                        local body = func_text:match("{(.-)%s*}%s*$")
                                        if body then
                                            for param in params:gmatch("([%w_]+)") do
                                                class_text = class_text
                                                    .. "    this."
                                                    .. param
                                                    .. " = "
                                                    .. param
                                                    .. ";\n"
                                            end
                                            class_text = class_text .. "    " .. body:gsub("\n", "\n    ") .. "\n  }\n"
                                        else
                                            class_text = class_text .. "  }\n"
                                        end
                                        for _, func in ipairs(related_funcs) do
                                            local method_text =
                                                content:match("function%s+" .. func .. "%s*%((.-)%)%s*{(.-)}")
                                            if method_text then
                                                local method_params = method_text:match("^(.-)%)") or ""
                                                local method_body = method_text:match("%)%s*{(.-)$") or ""
                                                local method_name = func:gsub(func_name, ""):lower()
                                                if method_name:sub(1, 1) == "_" then
                                                    method_name = method_name:sub(2)
                                                end
                                                class_text = class_text
                                                    .. "\n  "
                                                    .. method_name
                                                    .. "("
                                                    .. method_params
                                                    .. ") {"
                                                    .. method_body
                                                    .. "  }\n"
                                            end
                                        end
                                        class_text = class_text .. "}\n"
                                        local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                            local sr, sc, er, ec = node:range()
                                            return sr, sc, er, ec
                                        end)
                                        if not range_ok then
                                            return
                                        end
                                        pcall(
                                            vim.api.nvim_buf_set_text,
                                            bufnr,
                                            start_row,
                                            start_col,
                                            end_row,
                                            end_col,
                                            vim.split(class_text, "\n")
                                        )
                                    end,
                                })
                            end
                        end
                    end
                    if node:type() == "if_statement" then
                        local node_text_ok, if_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                        if not node_text_ok then
                            return actions
                        end
                        local ifelse_count = 0
                        for _ in if_text:gmatch("else%s+if") do
                            ifelse_count = ifelse_count + 1
                        end
                        if ifelse_count >= 2 then
                            local var_name = if_text:match("if%s*%((.-)%s*==") or if_text:match("if%s*%((.-)%s*===")
                            if var_name then
                                if filetype == "javascript" or filetype == "typescript" then
                                    table.insert(actions, {
                                        title = "Convert to switch statement",
                                        action = function()
                                            local switch_text = "switch (" .. var_name .. ") {\n"
                                            local if_node = node
                                            local if_nodes = { if_node }
                                            repeat
                                                local field_ok, else_clause = pcall(function()
                                                    return if_node:field("alternative")[1]
                                                end)
                                                if
                                                    field_ok
                                                    and else_clause
                                                    and else_clause:type() == "if_statement"
                                                then
                                                    table.insert(if_nodes, else_clause)
                                                    if_node = else_clause
                                                else
                                                    if_node = nil
                                                end
                                            until if_node == nil
                                            for _, if_n in ipairs(if_nodes) do
                                                local condition_ok, condition_node = pcall(function()
                                                    return if_n:field("condition")[1]
                                                end)
                                                if condition_ok and condition_node then
                                                    local condition_text_ok, condition =
                                                        pcall(vim.treesitter.get_node_text, condition_node, bufnr)
                                                    if condition_text_ok then
                                                        local case_value = condition:match("===%s*(.-)%s*$")
                                                            or condition:match("==%s*(.-)%s*$")
                                                        if case_value then
                                                            local consequent_ok, consequent_node = pcall(function()
                                                                return if_n:field("consequence")[1]
                                                            end)
                                                            if consequent_ok and consequent_node then
                                                                local consequent_text_ok, consequent = pcall(
                                                                    vim.treesitter.get_node_text,
                                                                    consequent_node,
                                                                    bufnr
                                                                )
                                                                if consequent_text_ok then
                                                                    switch_text = switch_text
                                                                        .. "  case "
                                                                        .. case_value
                                                                        .. ":\n"
                                                                        .. "    "
                                                                        .. consequent
                                                                            :gsub("^%s*{(.-)%s*}%s*$", "%1")
                                                                            :gsub("\n", "\n    ")
                                                                        .. "\n"
                                                                        .. "    break;\n"
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            local last_else_ok, last_else = pcall(function()
                                                return if_nodes[#if_nodes]:field("alternative")[1]
                                            end)
                                            if last_else_ok and last_else then
                                                local else_text_ok, else_body =
                                                    pcall(vim.treesitter.get_node_text, last_else, bufnr)
                                                if else_text_ok then
                                                    switch_text = switch_text
                                                        .. "  default:\n"
                                                        .. "    "
                                                        .. else_body
                                                            :gsub("^%s*{(.-)%s*}%s*$", "%1")
                                                            :gsub("\n", "\n    ")
                                                        .. "\n"
                                                        .. "    break;\n"
                                                end
                                            end
                                            switch_text = switch_text .. "}"
                                            local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                                local sr, sc, er, ec = node:range()
                                                return sr, sc, er, ec
                                            end)
                                            if not range_ok then
                                                return
                                            end
                                            pcall(
                                                vim.api.nvim_buf_set_text,
                                                bufnr,
                                                start_row,
                                                start_col,
                                                end_row,
                                                end_col,
                                                vim.split(switch_text, "\n")
                                            )
                                        end,
                                    })
                                    table.insert(actions, {
                                        title = "Convert to lookup object",
                                        action = function()
                                            local lookup_text = "const actions = {\n"
                                            local if_node = node
                                            local if_nodes = { if_node }
                                            repeat
                                                local field_ok, else_clause = pcall(function()
                                                    return if_node:field("alternative")[1]
                                                end)
                                                if
                                                    field_ok
                                                    and else_clause
                                                    and else_clause:type() == "if_statement"
                                                then
                                                    table.insert(if_nodes, else_clause)
                                                    if_node = else_clause
                                                else
                                                    if_node = nil
                                                end
                                            until if_node == nil
                                            for _, if_n in ipairs(if_nodes) do
                                                local condition_ok, condition_node = pcall(function()
                                                    return if_n:field("condition")[1]
                                                end)
                                                if condition_ok and condition_node then
                                                    local condition_text_ok, condition =
                                                        pcall(vim.treesitter.get_node_text, condition_node, bufnr)
                                                    if condition_text_ok then
                                                        local case_value = condition:match("===%s*(.-)%s*$")
                                                            or condition:match("==%s*(.-)%s*$")
                                                        if case_value then
                                                            local consequent_ok, consequent_node = pcall(function()
                                                                return if_n:field("consequence")[1]
                                                            end)
                                                            if consequent_ok and consequent_node then
                                                                local consequent_text_ok, consequent = pcall(
                                                                    vim.treesitter.get_node_text,
                                                                    consequent_node,
                                                                    bufnr
                                                                )
                                                                if consequent_text_ok then
                                                                    local body = consequent
                                                                        :gsub("^%s*{(.-)%s*}%s*$", "%1")
                                                                        :gsub("\n", "\n    ")
                                                                    lookup_text = lookup_text
                                                                        .. "  "
                                                                        .. case_value
                                                                        .. ": () => {\n"
                                                                        .. "    "
                                                                        .. body
                                                                        .. "\n  },\n"
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            lookup_text = lookup_text .. "  default: () => {\n"
                                            local last_else_ok, last_else = pcall(function()
                                                return if_nodes[#if_nodes]:field("alternative")[1]
                                            end)
                                            if last_else_ok and last_else then
                                                local else_text_ok, else_body =
                                                    pcall(vim.treesitter.get_node_text, last_else, bufnr)
                                                if else_text_ok then
                                                    lookup_text = lookup_text
                                                        .. "    "
                                                        .. else_body
                                                            :gsub("^%s*{(.-)%s*}%s*$", "%1")
                                                            :gsub("\n", "\n    ")
                                                        .. "\n"
                                                end
                                            else
                                                lookup_text = lookup_text .. "    // Default action\n"
                                            end
                                            lookup_text = lookup_text .. "  }\n};\n\n"
                                            lookup_text = lookup_text
                                                .. "(actions["
                                                .. var_name
                                                .. "] || actions['default'])();"
                                            local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                                local sr, sc, er, ec = node:range()
                                                return sr, sc, er, ec
                                            end)
                                            if not range_ok then
                                                return
                                            end
                                            pcall(
                                                vim.api.nvim_buf_set_text,
                                                bufnr,
                                                start_row,
                                                start_col,
                                                end_row,
                                                end_col,
                                                vim.split(lookup_text, "\n")
                                            )
                                        end,
                                    })
                                elseif filetype == "python" then
                                    table.insert(actions, {
                                        title = "Convert to dictionary dispatch",
                                        action = function()
                                            local dict_text = "actions = {\n"
                                            local if_node = node
                                            local if_nodes = { if_node }
                                            repeat
                                                local field_ok, else_clause = pcall(function()
                                                    return if_node:field("alternative")[1]
                                                end)
                                                if
                                                    field_ok
                                                    and else_clause
                                                    and else_clause:type() == "if_statement"
                                                then
                                                    table.insert(if_nodes, else_clause)
                                                    if_node = else_clause
                                                else
                                                    if_node = nil
                                                end
                                            until if_node == nil
                                            for _, if_n in ipairs(if_nodes) do
                                                local condition_ok, condition_node = pcall(function()
                                                    return if_n:field("condition")[1]
                                                end)
                                                if condition_ok and condition_node then
                                                    local condition_text_ok, condition =
                                                        pcall(vim.treesitter.get_node_text, condition_node, bufnr)
                                                    if condition_text_ok then
                                                        local case_value = condition:match("==%s*(.-)%s*$")
                                                        if case_value then
                                                            local consequent_ok, consequent_node = pcall(function()
                                                                return if_n:field("consequence")[1]
                                                            end)
                                                            if consequent_ok and consequent_node then
                                                                local consequent_text_ok, consequent = pcall(
                                                                    vim.treesitter.get_node_text,
                                                                    consequent_node,
                                                                    bufnr
                                                                )
                                                                if consequent_text_ok then
                                                                    dict_text = dict_text
                                                                        .. "    "
                                                                        .. case_value
                                                                        .. ": lambda: (\n"
                                                                        .. "        "
                                                                        .. consequent
                                                                            :gsub(":", ":\\n        ")
                                                                            :gsub("\n", "\n        ")
                                                                        .. "\n"
                                                                        .. "    ),\n"
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                            dict_text = dict_text .. "    'default': lambda: (\n"
                                            local last_else_ok, last_else = pcall(function()
                                                return if_nodes[#if_nodes]:field("alternative")[1]
                                            end)
                                            if last_else_ok and last_else then
                                                local else_text_ok, else_body =
                                                    pcall(vim.treesitter.get_node_text, last_else, bufnr)
                                                if else_text_ok then
                                                    dict_text = dict_text
                                                        .. "        "
                                                        .. else_body:gsub(":", ":\\n        "):gsub("\n", "\n        ")
                                                        .. "\n"
                                                end
                                            else
                                                dict_text = dict_text .. "        pass  # Default action\n"
                                            end
                                            dict_text = dict_text .. "    )\n};\n\n"
                                            dict_text = dict_text
                                                .. "actions.get("
                                                .. var_name
                                                .. ", actions['default'])()"
                                            local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                                local sr, sc, er, ec = node:range()
                                                return sr, sc, er, ec
                                            end)
                                            if not range_ok then
                                                return
                                            end
                                            pcall(
                                                vim.api.nvim_buf_set_text,
                                                bufnr,
                                                start_row,
                                                start_col,
                                                end_row,
                                                end_col,
                                                vim.split(dict_text, "\n")
                                            )
                                        end,
                                    })
                                end
                            end
                        end
                    end
                    if node:type():match("parameters") or node:type():match("parameter_list") then
                        local node_text_ok, params_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                        if not node_text_ok then
                            return actions
                        end
                        local param_count = 0
                        for _ in params_text:gmatch("([^,]+)") do
                            param_count = param_count + 1
                        end
                        if param_count >= 3 then
                            if filetype == "javascript" or filetype == "typescript" then
                                table.insert(actions, {
                                    title = "Convert to options object pattern",
                                    action = function()
                                        local params_list = {}
                                        for param in params_text:gmatch("([^,]+)") do
                                            table.insert(params_list, param:match("^%s*(.-)%s*$"))
                                        end
                                        local options_text = "{ " .. table.concat(params_list, ", ") .. " }"
                                        local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                            local sr, sc, er, ec = node:range()
                                            return sr, sc, er, ec
                                        end)
                                        if not range_ok then
                                            return
                                        end
                                        pcall(
                                            vim.api.nvim_buf_set_text,
                                            bufnr,
                                            start_row,
                                            start_col,
                                            end_row,
                                            end_col,
                                            { options_text }
                                        )
                                    end,
                                })
                            elseif filetype == "python" then
                                table.insert(actions, {
                                    title = "Convert params to **kwargs",
                                    action = function()
                                        local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                            local sr, sc, er, ec = node:range()
                                            return sr, sc, er, ec
                                        end)
                                        if not range_ok then
                                            return
                                        end
                                        pcall(
                                            vim.api.nvim_buf_set_text,
                                            bufnr,
                                            start_row,
                                            start_col,
                                            end_row,
                                            end_col,
                                            { "**kwargs" }
                                        )
                                    end,
                                })
                                table.insert(actions, {
                                    title = "Add kwargs unpacking inside function",
                                    action = function()
                                        local params_list = {}
                                        for param in params_text:gmatch("([^,]+)") do
                                            local param_name = param:match("^%s*(.-)%s*$"):gsub(":%s*.-$", "")
                                            table.insert(
                                                params_list,
                                                param_name .. " = kwargs.get('" .. param_name .. "')"
                                            )
                                        end
                                        local function_node = node:parent()
                                        while function_node and function_node:type() ~= "function_definition" do
                                            function_node = function_node:parent()
                                        end
                                        if function_node then
                                            local body_ok, body_node = pcall(function()
                                                return function_node:field("body")[1]
                                            end)
                                            if body_ok and body_node then
                                                local sr
                                                local range_ok
                                                range_ok, sr = pcall(function()
                                                    local start_row, _, _, _ = body_node:range()
                                                    return start_row
                                                end)
                                                if not range_ok then
                                                    return
                                                end
                                                local unpacking_text = ""
                                                for _, stmt in ipairs(params_list) do
                                                    unpacking_text = unpacking_text .. stmt .. "\n"
                                                end
                                                pcall(
                                                    vim.api.nvim_buf_set_lines,
                                                    bufnr,
                                                    sr + 1,
                                                    sr + 1,
                                                    false,
                                                    vim.split(unpacking_text, "\n")
                                                )
                                            end
                                        end
                                    end,
                                })
                            end
                        end
                    end
                    if filetype == "javascript" or filetype == "typescript" then
                        if node:type() == "variable_declaration" then
                            local node_text_ok, var_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                            if not node_text_ok then
                                return actions
                            end
                            if var_text:match("^var%s+") then
                                table.insert(actions, {
                                    title = "Convert var to const/let",
                                    action = function()
                                        local var_name = var_text:match("var%s+([%w_]+)")
                                        local has_reassignment = false
                                        local content = get_file_content()
                                        if
                                            var_name
                                            and content:match(var_name .. "%s*=")
                                            and not var_text:match(var_name .. "%s*=")
                                        then
                                            has_reassignment = true
                                        end
                                        local replacement
                                        if has_reassignment then
                                            replacement = var_text:gsub("^var%s+", "let ")
                                        else
                                            replacement = var_text:gsub("^var%s+", "const ")
                                        end
                                        local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                            local sr, sc, er, ec = node:range()
                                            return sr, sc, er, ec
                                        end)
                                        if not range_ok then
                                            return
                                        end
                                        pcall(
                                            vim.api.nvim_buf_set_text,
                                            bufnr,
                                            start_row,
                                            start_col,
                                            end_row,
                                            end_col,
                                            { replacement }
                                        )
                                    end,
                                })
                            end
                        end
                        if node:type() == "function" or node:type() == "function_expression" then
                            local node_text_ok, func_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                            if not node_text_ok then
                                return actions
                            end
                            if func_text:match("function%s*%(") then
                                table.insert(actions, {
                                    title = "Convert to arrow function",
                                    action = function()
                                        local params = func_text:match("function%s*%((.-)%)") or ""
                                        local body = func_text:match("{(.-)%s*}%s*$")
                                        local single_return = body and body:match("^%s*return%s+(.-)%s*;%s*$")
                                        local arrow_func
                                        if single_return then
                                            arrow_func = "(" .. params .. ") => " .. single_return
                                        else
                                            arrow_func = "(" .. params .. ") => {" .. (body or "") .. "}"
                                        end
                                        local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                            local sr, sc, er, ec = node:range()
                                            return sr, sc, er, ec
                                        end)
                                        if not range_ok then
                                            return
                                        end
                                        pcall(
                                            vim.api.nvim_buf_set_text,
                                            bufnr,
                                            start_row,
                                            start_col,
                                            end_row,
                                            end_col,
                                            { arrow_func }
                                        )
                                    end,
                                })
                            end
                        end
                    elseif filetype == "python" then
                        if node:type() == "for_statement" then
                            local node_text_ok, for_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                            if not node_text_ok then
                                return actions
                            end
                            if for_text:match("for%s+.+:%s*\n%s*[%w_]+%.append%(") then
                                table.insert(actions, {
                                    title = "Convert to list comprehension",
                                    action = function()
                                        local list_name = for_text:match("([%w_]+)%.append")
                                        local iterator = for_text:match("for%s+([%w_]+)%s+in")
                                        local iterable = for_text:match("in%s+([^:]+):")
                                        local expression = for_text:match("append%((.-)%)")
                                        if list_name and iterator and iterable and expression then
                                            local replacement = list_name
                                                .. " = ["
                                                .. expression
                                                .. " for "
                                                .. iterator
                                                .. " in "
                                                .. iterable
                                                .. "]"
                                            local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                                local sr, sc, er, ec = node:range()
                                                return sr, sc, er, ec
                                            end)
                                            if not range_ok then
                                                return
                                            end
                                            pcall(
                                                vim.api.nvim_buf_set_text,
                                                bufnr,
                                                start_row,
                                                start_col,
                                                end_row,
                                                end_col,
                                                { replacement }
                                            )
                                        end
                                    end,
                                })
                            end
                            if for_text:match("for%s+.+:%s*\n%s*if%s+.+:%s*\n%s*[%w_]+%.append") then
                                table.insert(actions, {
                                    title = "Convert to filtered list comprehension",
                                    action = function()
                                        local list_name = for_text:match("([%w_]+)%.append")
                                        local iterator = for_text:match("for%s+([%w_]+)%s+in")
                                        local iterable = for_text:match("in%s+([^:]+):")
                                        local condition = for_text:match("if%s+([^:]+):")
                                        local expression = for_text:match("append%((.-)%)")
                                        if list_name and iterator and iterable and expression and condition then
                                            local replacement = list_name
                                                .. " = ["
                                                .. expression
                                                .. " for "
                                                .. iterator
                                                .. " in "
                                                .. iterable
                                                .. " if "
                                                .. condition
                                                .. "]"
                                            local range_ok, start_row, start_col, end_row, end_col = pcall(function()
                                                local sr, sc, er, ec = node:range()
                                                return sr, sc, er, ec
                                            end)
                                            if not range_ok then
                                                return
                                            end
                                            pcall(
                                                vim.api.nvim_buf_set_text,
                                                bufnr,
                                                start_row,
                                                start_col,
                                                end_row,
                                                end_col,
                                                { replacement }
                                            )
                                        end
                                    end,
                                })
                            end
                        end
                        if node:type() == "function_definition" then
                            local node_text_ok, func_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                            if not node_text_ok then
                                return actions
                            end
                            local content = get_file_content()
                            if func_text:match("try:") and func_text:match("except%s+Exception") then
                                table.insert(actions, {
                                    title = "Add error handling decorator",
                                    action = function()
                                        local sr
                                        local range_ok
                                        range_ok, sr = pcall(function()
                                            local start_row, _ = node:range()
                                            return start_row
                                        end)
                                        if not range_ok then
                                            return
                                        end
                                        if not content:match("def handle_exceptions") then
                                            local decorator = [[
def handle_exceptions(func):
    def wrapper(*args, **kwargs):
        try:
            return func(*args, **kwargs)
        except Exception as e:
            print(f"Error in {func.__name__}: {e}")
            return None
    return wrapper

]]
                                            pcall(
                                                vim.api.nvim_buf_set_lines,
                                                bufnr,
                                                0,
                                                0,
                                                false,
                                                vim.split(decorator, "\n")
                                            )
                                            sr = sr + #vim.split(decorator, "\n")
                                        end
                                        pcall(
                                            vim.api.nvim_buf_set_lines,
                                            bufnr,
                                            sr,
                                            sr,
                                            false,
                                            { "@handle_exceptions" }
                                        )
                                    end,
                                })
                            end
                            if func_text:match("def%s+[%w_]+") and not func_text:match("@") then
                                table.insert(actions, {
                                    title = "Add timing decorator",
                                    action = function()
                                        local sr
                                        local range_ok
                                        range_ok, sr = pcall(function()
                                            local start_row, _ = node:range()
                                            return start_row
                                        end)
                                        if not range_ok then
                                            return
                                        end
                                        if not content:match("def timing_decorator") then
                                            local decorator = [[
import time

def timing_decorator(func):
    def wrapper(*args, **kwargs):
        start_time = time.time()
        result = func(*args, **kwargs)
        end_time = time.time()
        print(f"{func.__name__} executed in {end_time - start_time:.4f} seconds")
        return result
    return wrapper

]]
                                            pcall(
                                                vim.api.nvim_buf_set_lines,
                                                bufnr,
                                                0,
                                                0,
                                                false,
                                                vim.split(decorator, "\n")
                                            )
                                            sr = sr + #vim.split(decorator, "\n")
                                        end
                                        pcall(vim.api.nvim_buf_set_lines, bufnr, sr, sr, false, { "@timing_decorator" })
                                    end,
                                })
                            end
                        end
                    elseif filetype == "go" then
                        if node:type() == "function_declaration" then
                            local node_text_ok, func_text = pcall(vim.treesitter.get_node_text, node, bufnr)
                            if not node_text_ok then
                                return actions
                            end
                            if
                                func_text:match("return%s+err") and not func_text:match("%(.-%)%s*%(.-err%s+error%)")
                            then
                                table.insert(actions, {
                                    title = "Add named return values",
                                    action = function()
                                        local func_name = func_text:match("func%s+([%w_]+)")
                                        local params = func_text:match("func%s+[%w_]+%s*(%(.-%))") or "()"
                                        local returns = func_text:match("%)%s*(%(.-%))") or ""
                                        if returns ~= "" and not returns:match("[%w_]+%s+[%w_]+") then
                                            local named_returns = returns:gsub("(%w+)", "result %1")
                                            if returns:match("error") then
                                                named_returns = named_returns:gsub("error", "err error")
                                            end
                                            local new_signature = "func " .. func_name .. params .. " " .. named_returns
                                            local start_line = func_text:match("^([^\n]*)")
                                            if start_line then
                                                local sr, sc
                                                local func_range_ok
                                                func_range_ok, sr, sc = pcall(function()
                                                    local start_row, start_col, _, _ = node:range()
                                                    return start_row, start_col
                                                end)
                                                if not func_range_ok then
                                                    return
                                                end
                                                local signature_end = sc + #start_line
                                                pcall(
                                                    vim.api.nvim_buf_set_text,
                                                    bufnr,
                                                    sr,
                                                    sc,
                                                    sr,
                                                    signature_end,
                                                    { new_signature }
                                                )
                                            end
                                        end
                                    end,
                                })
                            end
                            if func_text:match("if%s+err%s+!=%s+nil") then
                                table.insert(actions, {
                                    title = "Use errors.Wrap for better context",
                                    action = function()
                                        local content = get_file_content()
                                        if not content:match('import%s+[%(%s]*"github%.com/pkg/errors"') then
                                            local import_stmt = 'import "github.com/pkg/errors"'
                                            local import_end = content:match("import%s+%((.-)%)")
                                            if import_end then
                                                local import_section = content:match("import%s+%(.-%)")
                                                local new_import =
                                                    import_section:gsub("%)", '\t"github.com/pkg/errors"\n)')
                                                pcall(
                                                    vim.api.nvim_buf_set_text,
                                                    bufnr,
                                                    0,
                                                    content:find("import%s+%("),
                                                    0,
                                                    content:find("import%s+%(.-%)") + #import_section - 1,
                                                    vim.split(new_import, "\n")
                                                )
                                            else
                                                local package_line = content:match("package%s+[%w_]+")
                                                if package_line then
                                                    local pkg_end = content:find(package_line) + #package_line
                                                    pcall(
                                                        vim.api.nvim_buf_set_text,
                                                        bufnr,
                                                        0,
                                                        pkg_end,
                                                        0,
                                                        pkg_end,
                                                        { "\n\n" .. import_stmt }
                                                    )
                                                end
                                            end
                                        end
                                        local func_lines = vim.split(func_text, "\n")
                                        local new_lines = {}
                                        for _, line in ipairs(func_lines) do
                                            if line:match("return%s+nil,%s*err") then
                                                local func_name = func_text:match("func%s+([%w_]+)")
                                                local new_line = line:gsub(
                                                    "return%s+nil,%s*err",
                                                    'return nil, errors.Wrap(err, "' .. func_name .. '")'
                                                )
                                                table.insert(new_lines, new_line)
                                            else
                                                table.insert(new_lines, line)
                                            end
                                        end
                                        local sr, sc, er, ec
                                        local func_range_ok
                                        func_range_ok, sr, sc, er, ec = pcall(function()
                                            local start_row, start_col, end_row, end_col = node:range()
                                            return start_row, start_col, end_row, end_col
                                        end)
                                        if not func_range_ok then
                                            return
                                        end
                                        pcall(vim.api.nvim_buf_set_text, bufnr, sr, sc, er, ec, new_lines)
                                    end,
                                })
                            end
                        end
                    end
                    return actions
                end,
            },
        }
        table.insert(sources, null_ls.register(advanced_transforms))
        if vim.fn.executable("prettier") == 1 then
            table.insert(
                sources,
                null_ls.builtins.formatting.prettier.with({
                    filetypes = { "javascript", "typescript", "css", "html", "json", "yaml", "markdown" },
                })
            )
        end
        local function find_venv()
            local launch_venv = os.getenv("VIRTUAL_ENV")
            if
                launch_venv
                and (
                    vim.fn.isdirectory(launch_venv .. "/bin") == 1
                    or vim.fn.isdirectory(launch_venv .. "\\Scripts") == 1
                )
            then
                return launch_venv .. (vim.fn.has("win32") == 1 and "\\Scripts" or "/bin")
            end
            local project_venv_paths = {
                ".venv/bin",
                "venv/bin",
                "env/bin",
                ".venv\\Scripts",
                "venv\\Scripts",
                "env\\Scripts",
            }
            local current_dir = vim.fn.getcwd()
            for _, path in ipairs(project_venv_paths) do
                local full_path = current_dir .. "/" .. path
                if vim.fn.isdirectory(full_path) == 1 then
                    return full_path:gsub("/", vim.fn.has("win32") == 1 and "\\" or "/")
                end
            end
            return nil
        end
        if vim.fn.executable("ruff") == 1 then
            table.insert(
                sources,
                null_ls.builtins.formatting.ruff.with({
                    prefer_local = find_venv(),
                    args = { "format", "--stdin-filename", "$FILENAME" },
                })
            )
            table.insert(
                sources,
                null_ls.builtins.diagnostics.ruff.with({
                    prefer_local = find_venv(),
                    args = { "check", "--stdin-filename", "$FILENAME", "--exit-zero" },
                })
            )
            table.insert(
                sources,
                null_ls.builtins.code_actions.ruff.with({
                    prefer_local = find_venv(),
                })
            )
        end
        if vim.fn.executable("isort") == 1 then
            table.insert(sources, null_ls.builtins.formatting.isort)
        end
        if vim.fn.executable("stylua") == 1 then
            table.insert(sources, null_ls.builtins.formatting.stylua)
        end
        if vim.fn.executable("gofmt") == 1 then
            table.insert(sources, null_ls.builtins.formatting.gofmt)
        end
        if vim.fn.executable("goimports") == 1 then
            table.insert(sources, null_ls.builtins.formatting.goimports)
        end
        if vim.fn.executable("shfmt") == 1 then
            table.insert(sources, null_ls.builtins.formatting.shfmt)
        end
        if vim.fn.executable("shellcheck") == 1 then
            table.insert(sources, null_ls.builtins.diagnostics.shellcheck)
            table.insert(sources, null_ls.builtins.code_actions.shellcheck)
        else
            print("shellcheck not found in PATH. Ensure it's installed and accessible.")
        end
        local function on_attach(client, bufnr)
            if client.supports_method("textDocument/formatting") then
                vim.api.nvim_create_autocmd("BufWritePre", {
                    group = vim.api.nvim_create_augroup("FormatOnSave" .. bufnr, { clear = true }),
                    buffer = bufnr,
                    callback = function()
                        vim.lsp.buf.format({ bufnr = bufnr })
                    end,
                })
            end
            if client.supports_method("textDocument/publishDiagnostics") then
                vim.lsp.handlers["textDocument/publishDiagnostics"] =
                    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
                        underline = true,
                        virtual_text = { spacing = 4, prefix = "●" },
                        signs = true,
                        update_in_insert = false,
                    })
            end
            if client.supports_method("textDocument/codeAction") then
                vim.api.nvim_create_autocmd("CursorHold", {
                    buffer = bufnr,
                    callback = function()
                        local line = vim.api.nvim_get_current_line()
                        if line:match("function") or line:match("if") or line:match("for") or line:match("var") then
                            vim.lsp.buf.code_action()
                        end
                    end,
                })
            end
        end
        null_ls.setup({
            sources = sources,
            on_attach = on_attach,
            debug = true,
        })
    end,
}
