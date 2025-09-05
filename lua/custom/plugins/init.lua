-- You can add your own plugins here or in other files in this directory!
--  I promise not to create any merge conflicts in this directory :)
--
-- See the kickstart.nvim README for more information
return {
  { -- send code from python/r/qmd documets to a terminal or REPL
    -- like ipython, R, bash
    'jpalardy/vim-slime',
    dev = false,
    init = function()
      vim.b['quarto_is_python_chunk'] = false
      Quarto_is_in_python_chunk = function()
        require('otter.tools.functions').is_otter_language_context 'python'
      end

      vim.cmd [[
      let g:slime_dispatch_ipython_pause = 100
      function SlimeOverride_EscapeText_quarto(text)
      call v:lua.Quarto_is_in_python_chunk()
      if exists('g:slime_python_ipython') && len(split(a:text,"\n")) > 1 && b:quarto_is_python_chunk && !(exists('b:quarto_is_r_mode') && b:quarto_is_r_mode)
      return ["%cpaste -q\n", g:slime_dispatch_ipython_pause, a:text, "--", "\n"]
      else
      if exists('b:quarto_is_r_mode') && b:quarto_is_r_mode && b:quarto_is_python_chunk
      return [a:text, "\n"]
      else
      return [a:text]
      end
      end
      endfunction
      ]]

      vim.g.slime_target = 'neovim'
      vim.g.slime_no_mappings = true
      vim.g.slime_python_ipython = 1
    end,
    config = function()
      vim.g.slime_input_pid = false
      vim.g.slime_suggest_default = true
      vim.g.slime_menu_config = false
      vim.g.slime_neovim_ignore_unlisted = true

      local function mark_terminal()
        local job_id = vim.b.terminal_job_id
        vim.print('job_id: ' .. job_id)
      end

      local function set_terminal()
        vim.fn.call('slime#config', {})
      end
      vim.keymap.set('n', '<leader>cm', mark_terminal, { desc = '[m]ark terminal' })
      vim.keymap.set('n', '<leader>cs', set_terminal, { desc = '[s]et terminal' })
      vim.keymap.set('n', '<leader>ti', "<cmd>vsplit term://zsh -i -c 'conda activate; ipython'<CR>", { desc = 'Base conda [i]python' })
      vim.keymap.set('n', '<leader>tp', "<cmd>vsplit term://zsh -i -c 'source venv/bin/activate; python'<CR>", { desc = 'Local venv python' })
      vim.keymap.set('n', '<leader>tu', "<cmd>vsplit term://zsh -i -c 'source venv/bin/activate; python'<CR>", { desc = 'Local .venv python' })
    end,
  },
  {
    'linux-cultist/venv-selector.nvim',
    dependencies = {
      'neovim/nvim-lspconfig',
      'mfussenegger/nvim-dap',
      'mfussenegger/nvim-dap-python', --optional
      { 'nvim-telescope/telescope.nvim', branch = '0.1.x', dependencies = { 'nvim-lua/plenary.nvim' } },
    },
    lazy = false,
    keys = {
      { ',v', '<cmd>VenvSelect<cr>' },
    },
    opts = {
      search = {
        anaconda_base = {
          command = 'fd /python$ ' .. vim.fn.expand '~/anaconda3/bin' .. ' --full-path --color never -E /proc',
          type = 'anaconda',
        },
      },
    },
  },
  {
    -- see the image.nvim readme for more information about configuring this plugin
    '3rd/image.nvim',
    opts = {
      backend = 'kitty', -- whatever backend you would like to use
      max_width = 100,
      max_height = 12,
      max_height_window_percentage = math.huge,
      max_width_window_percentage = math.huge,
      window_overlap_clear_enabled = true, -- toggles images when windows are overlapped
      window_overlap_clear_ft_ignore = { 'cmp_menu', 'cmp_docs', '' },
    },
  },
  {
    'GCBallesteros/jupytext.nvim',
    config = function()
      require('jupytext').setup {
        style = 'quarto',
        output_extension = 'qmd',
        force_ft = 'quarto',
      }
    end,
  },
  {
    'quarto-dev/quarto-nvim',
    ft = { 'quarto', 'markdown' },
    dependencies = {
      'jmbuhr/otter.nvim',
      'nvim-treesitter/nvim-treesitter',
    },
    config = function()
      require('quarto').setup {
        lspFeatures = {
          -- NOTE: put whatever languages you want here:
          languages = { 'r', 'python' },
          chunks = 'all',
          diagnostics = {
            enabled = true,
            triggers = { 'BufWritePost' },
          },
          completion = {
            enabled = true,
          },
        },
        codeRunner = {
          enabled = true,
          default_method = 'slime',
        },
      }
      local runner = require 'quarto.runner'
      vim.keymap.set('n', '<localleader>rc', runner.run_cell, { desc = 'run cell', silent = true })
      vim.keymap.set('n', '<localleader>ra', runner.run_above, { desc = 'run cell and above', silent = true })
      vim.keymap.set('n', '<localleader>rA', runner.run_all, { desc = 'run all cells', silent = true })
      vim.keymap.set('n', '<localleader>rl', runner.run_line, { desc = 'run line', silent = true })
      vim.keymap.set('v', '<localleader>r', runner.run_range, { desc = 'run visual range', silent = true })
      vim.keymap.set('n', '<localleader>RA', function()
        runner.run_all(true)
      end, { desc = 'run all cells of all languages', silent = true })
      local wk = require 'which-key'
      local is_code_chunk = function()
        local current, _ = require('otter.keeper').get_current_language_context()
        if current then
          return true
        else
          return false
        end
      end

      --- Insert code chunk of given language
      --- Splits current chunk if already within a chunk
      --- @param lang string
      local insert_code_chunk = function(lang)
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<esc>', true, false, true), 'n', true)
        local keys
        if is_code_chunk() then
          keys = [[o```<cr><cr>```{]] .. lang .. [[}<esc>o]]
        else
          keys = [[o```{]] .. lang .. [[}<cr>```<esc>O]]
        end
        keys = vim.api.nvim_replace_termcodes(keys, true, false, true)
        vim.api.nvim_feedkeys(keys, 'n', false)
      end

      local insert_r_chunk = function()
        insert_code_chunk 'r'
      end

      local insert_py_chunk = function()
        insert_code_chunk 'python'
      end

      -- normal mode
      wk.add({
        { '<c-LeftMouse>', '<cmd>lua vim.lsp.buf.definition()<CR>', desc = 'go to definition' },
        { '<c-q>', '<cmd>q<cr>', desc = 'close buffer' },
        { '<cm-i>', insert_py_chunk, desc = 'python code chunk' },
        { '<esc>', '<cmd>noh<cr>', desc = 'remove search highlight' },
        { '<m-I>', insert_py_chunk, desc = 'python code chunk' },
        { '<m-i>', insert_r_chunk, desc = 'r code chunk' },
        { '[q', ':silent cprev<cr>', desc = '[q]uickfix prev' },
        { ']q', ':silent cnext<cr>', desc = '[q]uickfix next' },
        { 'gN', 'Nzzzv', desc = 'center search' },
        { 'gf', ':e <cfile><CR>', desc = 'edit file' },
        { 'gl', '<c-]>', desc = 'open help link' },
        { 'n', 'nzzzv', desc = 'center search' },
        { 'z?', ':setlocal spell!<cr>', desc = 'toggle [z]pellcheck' },
        { 'zl', ':Telescope spell_suggest<cr>', desc = '[l]ist spelling suggestions' },
      }, { mode = 'n', silent = true })

      -- visual mode
      wk.add {
        {
          mode = { 'v' },
          { '.', ':norm .<cr>', desc = 'repat last normal mode command' },
          { '<M-j>', ":m'>+<cr>`<my`>mzgv`yo`z", desc = 'move line down' },
          { '<M-k>', ":m'<-2<cr>`>my`<mzgv`yo`z", desc = 'move line up' },
          { '<cr>', send_region, desc = 'run code region' },
          { 'q', ':norm @q<cr>', desc = 'repat q macro' },
        },
      }

      -- visual with <leader>
      wk.add({
        { '<leader>d', '"_d', desc = 'delete without overwriting reg', mode = 'v' },
        { '<leader>p', '"_dP', desc = 'replace without overwriting reg', mode = 'v' },
      }, { mode = 'v' })

      -- insert mode
      wk.add({
        {
          mode = { 'i' },
          { '<c-x><c-x>', '<c-x><c-o>', desc = 'omnifunc completion' },
          { '<cm-i>', insert_py_chunk, desc = 'python code chunk' },
          { '<m-->', ' <- ', desc = 'assign' },
          { '<m-I>', insert_py_chunk, desc = 'python code chunk' },
          { '<m-i>', insert_r_chunk, desc = 'r code chunk' },
          { '<m-m>', ' |>', desc = 'pipe' },
        },
      }, { mode = 'i' })
    end,
  },
}
