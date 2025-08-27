---@diagnostic disable-next-line: undefined-global
local vim = vim

return {
    dir = "~/kznllm.nvim",
    dependencies = { { "j-hui/fidget.nvim" } },
    config = function()
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
            anthropic = {
                system = get_template_path("anthropic", "fill_mode_system_prompt.xml.jinja"),
                user = get_template_path("anthropic", "fill_mode_user_prompt.xml.jinja"),
                debug = get_template_path("anthropic", "debug.xml.jinja"),
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

        local BasicAnthropicPreset = anthropic.AnthropicPresetBuilder
            :new()
            :add_system_prompts({ { type = "text", path = templates.anthropic.system } })
            :add_message_prompts({ { type = "text", role = "user", path = templates.anthropic.user } })

        local function auto_controls(q, sel, is_debug, max_tokens_cap)
            local qlen = (q and #q or 0) + (sel and #sel or 0)
            local verbosity
            if is_debug or qlen > 4000 then
                verbosity = "high"
            elseif qlen < 140 then
                verbosity = "low"
            else
                verbosity = "medium"
            end
            local effort = (verbosity == "low") and "minimal" or verbosity
            local out = (verbosity == "high") and 16384 or (verbosity == "medium" and 8192 or 2048)
            if max_tokens_cap and out > max_tokens_cap then
                out = max_tokens_cap
            end
            return verbosity, effort, out
        end

        local model_configs = {
            gpt5 = {
                id = "gpt-5",
                description = "OpenAI GPT-5",
                base_url = "https://api.openai.com",
                api_key_name = "OPENAI_API_KEY",
                max_tokens = 128000,
                endpoint = "responses", -- uses Responses API
                preset_builder = BasicOpenAIPreset,
                params = {
                    model = "gpt-5",
                    stream = true,
                    --verbosity auto determined as needed
                },
            },
            grok = {
                id = "grok-4",
                description = "xAI Grok 4",
                base_url = "https://api.x.ai",
                api_key_name = "XAI_API_KEY",
                max_tokens = 256000,
                preset_builder = BasicGrokPreset,
                params = {
                    model = "grok-4",
                    stream = true,
                    temperature = 0.7,
                    top_p = 0.95,
                },
            },
        }

        presets.options = presets.options or {}

        for _, model_info in pairs(model_configs) do
            local already_there = false
            for _, opt in ipairs(presets.options) do
                if opt.id == model_info.id then
                    already_there = true
                    break
                end
            end
            if not already_there then
                local provider
                if model_info.id:find("claude") then
                    provider = anthropic.AnthropicProvider:new({
                        base_url = model_info.base_url,
                        api_key_name = model_info.api_key_name,
                    })
                else
                    provider = openai.OpenAIProvider:new({
                        base_url = model_info.base_url,
                        api_key_name = model_info.api_key_name,
                        endpoint = model_info.endpoint,
                    })
                end

                local debug_template = model_info.id:find("claude") and templates.anthropic.debug
                    or (model_info.id:find("grok") and templates.grok.debug)
                    or templates.openai.debug

                local preset = model_info.preset_builder:with_opts({
                    provider = provider,
                    debug_template_path = debug_template,
                    params = model_info.params,
                })

                table.insert(presets.options, {
                    id = model_info.id,
                    description = model_info.description,
                    invoke = function(opts)
                        local user_query = (utils.get_user_input and utils.get_user_input())
                            or vim.fn.input("Enter your prompt: ")
                        if not user_query or user_query == "" then
                            vim.notify("[kznllm] Failed to get user input", vim.log.levels.ERROR)
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
                            vim.notify("[kznllm] Failed to build prompt arguments", vim.log.levels.ERROR)
                            return
                        end

                        if provider.endpoint == "responses" then
                            if curl_options.messages then
                                curl_options.input = curl_options.messages
                                curl_options.messages = nil
                            end
                            local verbosity, effort, out_tokens =
                                auto_controls(user_query, selection, opts and opts.debug, model_info.max_tokens)
                            curl_options.text = curl_options.text or {}
                            curl_options.text.verbosity = verbosity
                            curl_options.reasoning = { effort = effort }
                            curl_options.max_output_tokens = out_tokens
                            curl_options.stream = true
                        end

                        if opts and opts.debug and preset.debug_template_path then
                            local scratch_buf_id = buffer_manager:create_scratch_buffer()
                            local ok, debug_data = pcall(utils.make_prompt_from_template, {
                                template_path = preset.debug_template_path,
                                prompt_args = curl_options,
                            })
                            if ok and debug_data then
                                buffer_manager:write_content(debug_data, scratch_buf_id)
                                vim.cmd("normal! Gzz")
                            else
                                vim.notify("[kznllm] Failed to create debug data", vim.log.levels.ERROR)
                            end
                        end

                        local args = provider:make_curl_args(curl_options)
                        p:report({ message = model_info.description })
                        buffer_manager:create_streaming_job(args, provider.handle_sse_stream, function()
                            p:report({ message = "Working..." })
                        end, function()
                            local completion_message =
                                string.format("Completed in %ds", os.time() - invoke_state.start_time)
                            p:report({ message = completion_message })
                            p:finish()
                        end)
                    end,
                })
            end
        end

        vim.keymap.set({ "n", "v" }, "<leader>m", function()
            presets.switch_presets(presets.options)
        end, { desc = "Switch between model presets" })

        local function invoke_with_opts(opts)
            return function()
                local preset = presets.load_selected_preset(presets.options)
                if preset and preset.invoke then
                    preset.invoke(opts)
                else
                    vim.notify("[kznllm] No preset selected or invoke missing", vim.log.levels.WARN)
                end
            end
        end

        vim.keymap.set({ "n", "v" }, "<leader>K", invoke_with_opts({ debug = true }), { desc = "Invoke LLM (debug)" })
        vim.keymap.set({ "n", "v" }, "<leader>k", invoke_with_opts({ debug = false }), { desc = "Invoke LLM" })

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
}
