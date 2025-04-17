return {
    {
        "chottolabs/kznllm.nvim",
        dependencies = { { "j-hui/fidget.nvim" } },
        config = function(self)
            local presets = require("kznllm.presets.basic")
            local utils = require("kznllm.utils")
            local openai = require("kznllm.specs.openai")
            local anthropic = require("kznllm.specs.anthropic")
            local buffer_manager = require("kznllm.buffer").buffer_manager
            local progress = require("fidget.progress")
            local TEMPLATE_DIR = utils.TEMPLATE_PATH

            local function get_template_path(model, filename)
                return utils.join_path({ TEMPLATE_DIR, model, filename })
            end

            local templates = {
                openai = {
                    system = get_template_path("openai", "fill_mode_system_prompt.xml.jinja"),
                    user = get_template_path("openai", "fill_mode_user_prompt.xml.jinja"),
                    debug = get_template_path("openai", "debug.xml.jinja"),
                },
                grok = {
                    system = get_template_path("grok", "fill_mode_system_prompt.xml.jinja"),
                    user = get_template_path("grok", "fill_mode_user_prompt.xml.jinja"),
                    debug = get_template_path("grok", "debug.xml.jinja"),
                },
            }
            local BasicOpenAIPreset = openai.OpenAIPresetBuilder
                :new()
                :add_system_prompts({ { type = "text", path = templates.openai.system } })
                :add_message_prompts({ { type = "text", role = "user", path = templates.openai.user } })

            local BasicGrokPreset = openai.OpenAIPresetBuilder
                :new()
                :add_system_prompts({ { type = "text", path = templates.grok.system } })
                :add_message_prompts({ { type = "text", role = "user", path = templates.grok.user } })

            local model_configs = {
                gpt4 = {
                    id = "gpt-4.1",
                    description = "OpenAI GPT-4.1",
                    base_url = "https://api.openai.com",
                    max_tokens = 12000,
                    preset_builder = BasicOpenAIPreset,
                    api_key_name = "OPENAI_API_KEY",
                    params = {
                        model = "gpt-4.1",
                        stream = true,
                        temperature = 0.5,
                        top_p = 0.95,
                        frequency_penalty = 0,
                        presence_penalty = 0,
                    },
                },
                grok = {
                    id = "grok-3",
                    description = "xAI Grok 3",
                    base_url = "https://api.x.ai",
                    api_key_name = "XAI_API_KEY",
                    max_tokens = 131072,
                    preset_builder = BasicGrokPreset,
                    params = {
                        model = "grok-3",
                        stream = true,
                        temperature = 0.7,
                        top_p = 0.95,
                        frequency_penalty = 0,
                        presence_penalty = 0,
                    },
                },
            }

            presets.options = presets.options or {}

            local function create_enhanced_invoke(config)
                local provider = openai.OpenAIProvider:new({
                    base_url = config.base_url,
                    api_key_name = config.api_key_name,
                })
                local debug_template = config.id:find("grok") and templates.grok.debug or templates.openai.debug
                local preset = config.preset_builder:with_opts({
                    provider = provider,
                    debug_template_path = debug_template,
                    params = config.params or {
                        model = config.id,
                        stream = true,
                        temperature = 0.7,
                        top_p = 0.9,
                        max_tokens = config.max_tokens,
                    },
                })
                return function(opts)
                    local function get_input_fallback()
                        local success, result = pcall(utils.get_user_input)
                        if success and result then
                            return result
                        end
                        local input = vim.fn.input("Enter your prompt: ")
                        if input and input ~= "" then
                            return input
                        end
                        return nil
                    end
                    local user_query = get_input_fallback()
                    if not user_query then
                        vim.notify("Failed to get user input", vim.log.levels.ERROR)
                        return
                    end
                    local selection, replace = utils.get_visual_selection(opts)
                    local current_buf_id = vim.api.nvim_get_current_buf()
                    local current_buffer_context = buffer_manager:get_buffer_context(current_buf_id)

                    local invoke_state = { start_time = os.time() }
                    local p = progress.handle.create({
                        title = ("[%s]"):format(replace and "Replacing" or "Processing"),
                        lsp_client = { name = "kznllm" },
                    })

                    local prompt_args = {
                        user_query = user_query,
                        visual_selection = selection,
                        current_buffer_context = current_buffer_context,
                        replace = replace,
                        context_files = utils.get_project_files(),
                    }
                    local curl_options = preset:build(prompt_args)
                    if not curl_options then
                        vim.notify("Failed to build prompt arguments", vim.log.levels.ERROR)
                        return
                    end
                    if opts and opts.debug then
                        local scratch_buf_id = buffer_manager:create_scratch_buffer()
                        local success, debug_data = pcall(utils.make_prompt_from_template, {
                            template_path = preset.debug_template_path,
                            prompt_args = curl_options,
                        })
                        if success and debug_data then
                            buffer_manager:write_content(debug_data, scratch_buf_id)
                            vim.cmd("normal! Gzz")
                        else
                            vim.notify("Failed to create debug data", vim.log.levels.ERROR)
                        end
                    end

                    local args = provider:make_curl_args(curl_options)
                    p:report({ message = config.description })
                    buffer_manager:create_streaming_job(args, provider.handle_sse_stream, function()
                        p:report({ message = "Working..." })
                    end, function()
                        local completion_message =
                            string.format("Completed in %ds", os.time() - invoke_state.start_time)
                        p:report({ message = completion_message })
                        p:finish()
                    end)
                end
            end

            for _, model_info in pairs(model_configs) do
                table.insert(presets.options, {
                    id = model_info.id,
                    description = model_info.description,
                    invoke = create_enhanced_invoke(model_info),
                })
            end

            vim.keymap.set({ "n", "v" }, "<leader>m", function()
                presets.switch_presets(presets.options)
            end, { desc = "Switch between model presets" })

            local function invoke_with_opts(opts)
                return function()
                    local preset = presets.load_selected_preset(presets.options)
                    if preset then
                        preset.invoke(opts)
                    else
                        vim.notify("No preset selected", vim.log.levels.WARN)
                    end
                end
            end

            vim.keymap.set(
                { "n", "v" },
                "<leader>K",
                invoke_with_opts({ debug = true }),
                { desc = "Invoke LLM with debug mode" }
            )
            vim.keymap.set(
                { "n", "v" },
                "<leader>k",
                invoke_with_opts({ debug = false }),
                { desc = "Invoke LLM for completion" }
            )

            vim.api.nvim_set_keymap("n", "<Esc>", "", {
                noremap = true,
                silent = true,
                callback = function()
                    vim.api.nvim_exec_autocmds("User", { pattern = "LLM_Escape" })
                end,
            })

            local function setup_cleanup_autocmds()
                vim.api.nvim_create_augroup("LLMCleanup", { clear = true })
                vim.api.nvim_create_autocmd("VimLeavePre", {
                    group = "LLMCleanup",
                    callback = function()
                        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                            if vim.api.nvim_buf_get_option(buf, "buftype") == "nofile" then
                                pcall(vim.api.nvim_buf_delete, buf, { force = true })
                            end
                        end
                    end,
                })
            end

            setup_cleanup_autocmds()
        end,
    },
}
