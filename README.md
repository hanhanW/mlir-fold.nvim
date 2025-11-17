# mlir-fold.nvim

Neovim plugin for automatically folding MLIR IR dump sections with beautiful display and crash trace preservation.

## Features

- 🔍 **Auto-detects MLIR IR dump markers** - Works with any file containing IR dumps
- 📁 **Automatic folding** - Each IR dump section is foldable independently
- 🏷️ **Beautiful fold display** - Shows pass names (Before/After), line counts with diamond decorators
- ⚡ **Zero configuration** - Works out of the box
- 🚀 **Optimized for large files** - Fast performance even with huge log files
- 🎯 **Only activates when needed** - No overhead for non-MLIR files
- 🛡️ **Error/crash preservation** - Stack traces and error messages stay visible
- 🔄 **Pass detection** - Supports "Before" and "After" passes, including failed passes
- 📝 **No file modifications** - Pure read-only folding

## Requirements

- Neovim >= 0.8
- No external dependencies. Be careful with other folding plugins that may
  conflict. E.g., disable `nvim-ufo` for MLIR files (see Tips & Troubleshooting)

## Installation

### lazy.nvim
```lua
{
  'hanhanW/mlir-fold.nvim',
  ft = 'mlir',
}
```

### packer.nvim
```lua
use 'hanhanW/mlir-fold.nvim'
```

### vim-plug
```vim
Plug 'hanhanW/mlir-fold.nvim'
```

### Fold Commands (Standard Vim)

- `zo` - Open fold under cursor
- `zc` - Close fold under cursor
- `zR` - Open all folds
- `zM` - Close all folds
- `zj` - Jump to next fold
- `zk` - Jump to previous fold
- `za` - Toggle fold under cursor

## Example Display

When you open an MLIR log file with IR dumps:

```
◆ IR Dump After MaterializeTargetDevicesPass (iree-hal-materialize-target-devices) ◆ 89 lines

[IR dump content FOLDED]

◆ IR Dump After ResolveDevicePromisesPass (iree-hal-resolve-device-promises) ◆ 87 lines

[IR dump content FOLDED]

iree-compile: ....: Assertion `false' failed.
Stack dump:
0.	Program arguments: build/tools/iree-compile ...
 #0 0x0000713fdbb0b2e8 llvm::sys::PrintStackTrace(...)
 #1 0x0000713fdbb08f70 llvm::sys::RunSignalHandlers(...)
[... stack frames remain visible ...]
```

## How It Works

### Folding Strategy
- Each IR dump section (from marker to next marker) is a fold
- Error messages and stack traces are **never folded**
- Fold level 1 (flat) - no nested folds

### Detection Patterns
- **IR dump markers:** `// -----// IR Dump (Before|After) ...`
- **Error messages:** File path errors like `/path/file.mlir:line:col: error:`
- **Stack traces:** `Stack dump:`, `#0 0x...`, `#1 0x...`, etc.
- **Compiler errors:** `iree-compile:`, `iree-opt:`, `mlir-opt:`, etc.

### Performance Optimizations
- ✅ Only triggers on `.mlir` files (zero overhead for other files)
- ✅ Pre-compiled regex patterns (no recompilation overhead)
- ✅ Simplified error detection with early exit strategy
- ✅ Optimized for files 10K+ lines

## Supported Compiler Tools

The plugin detects and preserves errors from:
- `iree-compile`
- `iree-opt`
- `mlir-opt`
- Any tool following the pattern `<tool>: error message`

## Tips & Troubleshooting

### Using with nvim-ufo

If you use [nvim-ufo](https://github.com/kevinhwang91/nvim-ufo), you should disable it for MLIR files to use mlir-fold.nvim's folding instead:

```lua
{
  'kevinhwang91/nvim-ufo',
  config = function()
    require('ufo').setup({
      provider_selector = function(bufnr, filetype, buftype)
        -- Disable ufo for MLIR files (use mlir-fold.nvim instead)
        if filetype == 'mlir' then
          return ''
        end
        return { 'treesitter', 'indent' }
      end,
    })
  end,
}
```

This ensures mlir-fold.nvim has full control over folding for MLIR files.
