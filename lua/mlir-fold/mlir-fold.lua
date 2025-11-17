-- MLIR IR Dump Folding Plugin
-- Automatically folds MLIR IR dump sections in files containing them
-- Optimized for performance with large files

local M = {}

-- Pre-compiled patterns for better performance
local IR_DUMP_PATTERN = "^// %-%-%-%-%-// IR Dump"
local FILE_ERROR_PATTERN = "^/.+%.mlir:%d+:%d+:"
local CARET_PATTERN = "^%s*%^%s*$"
local BLANK_PATTERN = "^%s*$"
local COMPILER_ERROR_PATTERN = "^[a-z%-]+[:-]"
local STACK_FRAME_PATTERN = "^%s*#%d+%s+0x"
local ASSERTION_PATTERN = "Assertion.*failed"
local STACK_DUMP_PATTERN = "^Stack dump:"

-- Check if a line is a crash/error/stack trace marker
local function is_crash_marker(line)
  if line:match(ASSERTION_PATTERN) then
    return true
  end
  if line:match(STACK_DUMP_PATTERN) or line:match("^core dump") then
    return true
  end
  if line:match(STACK_FRAME_PATTERN) then
    return true
  end
  return false
end

-- Simplified and optimized error context detection
-- Early exit for most common cases
local function is_error_context(lnum)
  local line = vim.fn.getline(lnum)

  -- Quick checks first (cheap operations)
  if line:match(FILE_ERROR_PATTERN) then
    return true
  end

  if line:match(CARET_PATTERN) then
    return true
  end

  if is_crash_marker(line) then
    return true
  end

  -- For blank lines and compiler errors, only look at adjacent lines when needed
  if line:match(BLANK_PATTERN) then
    local next_line = vim.fn.getline(lnum + 1)
    if next_line:match(COMPILER_ERROR_PATTERN) then
      return true
    end
    local prev_line = vim.fn.getline(lnum - 1)
    if prev_line:match(FILE_ERROR_PATTERN) then
      return true
    end
    return false
  end

  -- For non-blank lines, check if they're at the start of an error block
  if line:match(COMPILER_ERROR_PATTERN) then
    local prev_line = lnum > 1 and vim.fn.getline(lnum - 1) or ""
    if prev_line:match(BLANK_PATTERN) then
      return true
    end
  end

  -- Check previous line for error context
  local prev_line = lnum > 1 and vim.fn.getline(lnum - 1) or ""

  if prev_line:match(FILE_ERROR_PATTERN) and line:match("^%s+") then
    return true
  end

  if prev_line:match(STACK_FRAME_PATTERN) then
    if line:match(STACK_FRAME_PATTERN) or line:match(BLANK_PATTERN) or line:match("^%s+") then
      return true
    end
  end

  if is_crash_marker(prev_line) then
    return true
  end

  return false
end

-- Check if buffer contains any IR dump markers (cached per buffer)
local buffer_has_ir_dumps = {}
local function has_ir_dumps_in_buffer(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Return cached result if available
  if buffer_has_ir_dumps[bufnr] ~= nil then
    return buffer_has_ir_dumps[bufnr]
  end

  -- Check first 10000 lines for performance
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local check_limit = math.min(line_count, 10000)

  for i = 1, check_limit do
    local line = vim.fn.getline(i)
    if line:match(IR_DUMP_PATTERN) then
      buffer_has_ir_dumps[bufnr] = true
      return true
    end
  end

  buffer_has_ir_dumps[bufnr] = false
  return false
end

-- Custom fold expression for MLIR IR dumps
local function mlir_fold_expr(lnum)
  local line = vim.fn.getline(lnum)

  -- If buffer has no IR dumps, don't fold anything
  if not has_ir_dumps_in_buffer() then
    return "0"
  end

  -- Start a new fold at IR dump markers (including "Failed" passes)
  if line:match(IR_DUMP_PATTERN) then
    return ">1"
  end

  -- Don't fold error/diagnostic lines and their context
  if is_error_context(lnum) then
    return "0"
  end

  -- Everything else continues at fold level 1 (flat folding, no nesting)
  return "1"
end

-- Custom fold text to show the IR dump header with line count
local function mlir_fold_text()
  local line = vim.fn.getline(vim.v.foldstart)
  -- Extract the full "IR Dump After/Before <Pass Name> (...)" part
  local pass_info = line:match("IR Dump [^/]+") or line
  pass_info = pass_info:gsub("^%s+", ""):gsub("%s+$", "")

  -- Calculate number of folded lines
  local line_count = vim.v.foldend - vim.v.foldstart + 1

  -- Create beautiful fold text with decorative diamonds and line count
  return string.format("◆ %s ◆ %d lines", pass_info, line_count)
end

-- Setup function for a buffer
local function setup_buffer_folding(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()

  -- Clear cache for this buffer to force re-check
  buffer_has_ir_dumps[bufnr] = nil

  -- Get the window displaying this buffer
  local winid = vim.fn.bufwinid(bufnr)
  if winid == -1 then
    -- Buffer not displayed in any window, set options for current window
    winid = 0
  end

  -- Set up window-local folding options
  vim.wo[winid].foldmethod = 'expr'
  vim.wo[winid].foldexpr = 'v:lua.require("mlir-fold.mlir-fold").fold_expr(v:lnum)'
  vim.wo[winid].foldtext = 'v:lua.require("mlir-fold.mlir-fold").fold_text()'

  -- Start with all folds closed
  vim.cmd('normal! zM')
end

-- Setup autocmd - only for .mlir files
local function setup()
  local augroup = vim.api.nvim_create_augroup('MLIRFold', { clear = true })

  -- Only check MLIR files (removed BufReadPost for all files)
  vim.api.nvim_create_autocmd('FileType', {
    group = augroup,
    pattern = 'mlir',
    callback = function(args)
      vim.schedule(function()
        setup_buffer_folding(args.buf)
      end)
    end,
  })
end

-- Export functions for use in foldexpr and foldtext
M.fold_expr = mlir_fold_expr
M.fold_text = mlir_fold_text
M.setup = setup

-- Return the module for direct use
return M
